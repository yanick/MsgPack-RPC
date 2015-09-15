package MsgPack::Decoder;
# ABSTRACT: Decode data from a MessagePack stream

=head1 SYNOPSIS

    use MsgPack::Decoder;

    use MsgPack::Encoder;
    use Data::Printer;

    my $decoder = MsgPack::Decoder->new;

    my $msgpack_binary = MsgPack::Encoder->new(struct => [ "hello world" ] )->encoded;

    $decoder->read( $msgpack_binary );

    my $struct = $decode->next;  

    p $struct;    # prints [ 'hello world' ]

    
=head2 DESCRIPTION

C<MsgPack::Decoder> objects take in the raw binary representation of 
one or more MessagePack data structures, and convert it back into their
Perl representations.

=head1 CURRENTLY SUPPORTED MESSAGEPACK TYPES

I'm implementing the different messagepack types as I go along. So far, the
current types are supported:

=over

=item Boolean

=item PositiveFixInt

=item NegativeFixInt

=item FixStr

=item Str8

=item FixArray

=item Nil

=item FixMap

=item FixExt1

=back

=head2 METHODS

This class consumes L<MooseX::Role::Loggable>, and inherits all of its
methods.

=cut

use 5.20.0;

use strict;
use warnings;

use MsgPack::Type::Boolean;

use Moose;

use List::AllUtils qw/ reduce first first_index any /;

use List::Gather;

use experimental 'signatures', 'postderef';

with 'MooseX::Role::Loggable' => {
    -excludes => [ 'Bool' ],
};

=head3 read( @binary_values ) 

Reads in the raw binary to convert. The binary can be only a partial piece of the 
encoded structures.  If so, all structures that can be decoded will be
made available in the buffer, while the potentially last unterminated structure will
remain "in flight".

Returns how many structures were decoded.

=cut

sub read($self,@values) {
    $self->log_debug( [ "raw bytes: %s", \@values ] );

    my @new = gather {
        $self->gen_next( 
            reduce {
                my $g = $a->($b);
                is_gen($g) or do { take $$g; gen_new_value() }
            } $self->gen_next => map { ord } map { split '' } @values
        );
    };

    $self->add_to_buffer(@new);

    return scalar @new;
}


=head3 has_buffer

Returns the number of decoded structures currently waiting in the buffer.

=head3 next

Returns the next structure from the buffer.

    $decoder->read( $binary );

    while( $decoder->has_buffer ) {
        my $next = $decoder->next;
        do_stuff( $next );
    }

Note that the returned structure could be C<undef>, so don't do:

    $decoder->read( $binary );

    # NO! $next could be 'undef'
    while( my $next = $decoder->next ) {
        do_stuff( $next );
    }

=head3 all 

Returns (and flush from the buffer) all the currently available structures.

=cut


has buffer => (
    is => 'rw',
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        'has_buffer' => 'count',
        next => 'shift',
        all => 'elements',
        add_to_buffer => 'push',
    },
);

after all => sub($self) {
    $self->buffer([]);
};

has gen_next => (
    is =>  'rw',
    clearer => 'clear_gen_next',
    default => sub { 
        gen_new_value();
    }

);

=head3 read_all( @binaries )

Reads the provided binary data and returns all structured decoded so far.

    
    @data = $decoder->read_all($binary);

    # equivalent to
    
    $decoder->read(@binaries);
    @data = $decoder->all;

=cut

sub read_all($self,@vals){
    $self->read(@vals);
    $self->all;
}

sub is_gen($val) { ref $val eq 'CODE' and $val }

use Types::Standard qw/ Str ArrayRef Int Any InstanceOf Ref /;
use Type::Tiny;

my $MessagePackGenerator  = Type::Tiny->new(
    parent => Ref,
    name   => 'MessagePackGenerator',
);

my @msgpack_types = (
    [ PositiveFixInt => [    0, 0x7f ], \&gen_positive_fixint ],
    [ NegativeFixInt => [  0xe0, 0xff ], \&gen_negative_fixint ],
    [ FixArray       => [ 0x90, 0x9f ], \&gen_fixarray ],
    [ Array16       => [ 0xdc ], \&gen_array16 ],
    [ FixMap         => [ 0x80, 0x8f ], \&gen_fixmap ],
    [ FixStr         => [ 0xa0, 0xbf ], \&gen_fixstr ],
    [ Str8           => [ 0xd9 ], \&gen_str8 ],
    [ Uint64         => [ 0xcf ], \&gen_uint64 ],
    [ Bin8           => [ 0xc4 ], \&gen_bin8 ],
    [ Nil            => [ 0xc0 ], \&gen_nil ],
    [ True           => [ 0xc3 ], \&gen_true ],
    [ False          => [ 0xc2 ], \&gen_false ],
    [ Int8           => [ 0xd0 ], \&gen_int8 ],
    [ FixExt1        => [ 0xd4 ], \&gen_fixext1 ],
);

$MessagePackGenerator = $MessagePackGenerator->plus_coercions(
    map {
        my( $min, $max ) = $_->[1]->@*;
        Type::Tiny->new(
            parent     => Int,
            name       => $_->[0],
            constraint => sub { $max ? ( $_ >= $min and $_ <= $max ) : ( $_ == $min ) },
        ) => $_->[2]  
    } @msgpack_types
);

sub  gen_true  { my $x = MsgPack::Type::Boolean->new(1); \$x }
sub  gen_false { my $x = MsgPack::Type::Boolean->new(0); \$x }

sub read_n_bytes($size) {
    my $value = '';

    sub($byte) {
        $value .= chr $byte;
        --$size ? __SUB__ : \$value;
    }
}

sub read_n_bytes_as_int($size) {
    my $gen = read_n_bytes($size);

    sub($byte) {
        $gen = $gen->($byte);

        return __SUB__ if is_gen($gen);

        my $x = reduce { ( $a << 8 ) + $b } map { ord } split '', $$gen;
        return \$x;
    }
}

sub gen_str8 {
    my $gen = read_n_bytes_as_int(1);

    sub($byte) {
        $gen = $gen->($byte);
        is_gen($gen) ? __SUB__ : gen_str($$gen);
    }
}

sub gen_array16 {
    my $size = read_n_bytes_as_int(2);

    sub($byte) {
        $size = $size->($byte);

        is_gen($size) ? __SUB__ : gen_array($$size);
    };
}

sub gen_nil {
    \my $undef;
}

sub gen_new_value { 
    sub ($byte) { $MessagePackGenerator->assert_coerce($byte); } 
}

sub gen_int8 {
    gen_int(1);
}

sub gen_int($size) {
    my $gen = read_n_bytes($size);
    sub($byte) {
        $gen = $gen->($byte);
        is_gen($gen) ? __SUB__ : $gen;
    }
}

sub gen_bin8 {
    gen_binary(1);
}

sub gen_binary {
    sub($byte) {
        my $size = $byte;
        my $bin = '';

        sub ($byte) {
            $bin .= chr($byte);
            --$size ? __SUB__ : \$bin;
        }
    }
}

sub gen_uint64 {
    gen_unsignedint(8);
}

sub gen_unsignedint {
    my $left_to_read = shift;
    my $value = 0;

    sub($byte) {
        $value = $byte + ($value << 8);
        --$left_to_read ? __SUB__ : \$value;
    }
}

sub gen_fixext1 {
    my $gen = read_n_bytes(2);
    sub($byte) {
        $gen = $gen->($byte);
        return __SUB__ if is_gen($gen);

        my($type, $data) = split '', $$gen, 2;
        $type = ord $type;
        my $ext = MsgPack::Type::Ext->new(
            fix  => 1,
            size => 1,
            data => $data,
            type => $type,
        );

        return \$ext;

    }
}

sub gen_positive_fixint { \$_  }
sub gen_negative_fixint { my $x = 0xe0 - $_; \$x; }

sub gen_fixarray {
    gen_array( $_ - 0x90 );
}

sub gen_fixmap {
    gen_map($_ - 0x80);
}

sub gen_fixstr {
    gen_str( $_ - 0xa0 );
}

sub gen_str($size) {
    my $gen = read_n_bytes($size);
    sub($byte) {
        $gen = $gen->($byte);
        is_gen($gen) ? __SUB__ : $gen;
    }
}


sub gen_map($size) {
    return \{} unless $size;

    my $gen = gen_array( 2*$size );

    use Data::Printer;
    sub($byte) {
        $gen = $gen->($byte);
        is_gen( $gen ) ? __SUB__ : \{ @$$gen };
    }
}

sub gen_array($size) {

    return \[] unless $size;

    my @array;

    @array = map { gen_new_value() } 1..$size;

    sub($byte) {
        $_ = $_->($byte) for first { is_gen($_) } @array;

        ( any { is_gen($_) } @array ) ? __SUB__ : \[ map { $$_ } @array ];
    }
}


1;
