package MessagePack::Decoder;

use 5.20.0;

use strict;
use warnings;

use Moose;

use List::AllUtils qw/ reduce first first_index any /;

use List::Gather;

use experimental 'signatures', 'postderef';

with 'MooseX::Role::Loggable' => {
    -excludes => [ 'Bool' ],
};

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

sub is_gen($val) { ref $val eq 'CODE' and $val }

sub read($self,@values) {
    $self->log_debug( [ "raw bytes: %s", \@values ] );

    $self->add_to_buffer( gather {
        $self->gen_next( 
            reduce {
                my $g = $a->($b);
                is_gen($g) or do { take $$g; gen_new_value() }
            } $self->gen_next => map { ord } map { split '' } @values
        );
    } );

}

use Types::Standard qw/ Str ArrayRef Int Any InstanceOf Ref /;
use Type::Tiny;

my $MessagePackGenerator  = Type::Tiny->new(
    parent => Ref,
    name   => 'MessagePackGenerator',
);

my @msgpack_types = (
    [ PositiveFixInt => [    0, 0x7f ], \&gen_positive_fixint ],
    [ FixArray       => [ 0x90, 0x9f ], \&gen_fixarray ],
    [ Array16       => [ 0xdc ], \&gen_array16 ],
    [ FixMap         => [ 0x80, 0x8f ], \&gen_fixmap ],
    [ Uint64         => [ 0xcf ], \&gen_uint64 ],
    [ Bin8           => [ 0xc4 ], \&gen_bin8 ],
    [ Nil            => [ 0xc0 ], \&gen_nil ],
    [ True           => [ 0xc3 ], \&gen_true ],
    [ False          => [ 0xc2 ], \&gen_false ],
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

sub  gen_true { my $x = 1; \$x }
sub  gen_false { my $x = 0; \$x }

sub read_n_bytes_as_int($size) {
    my $num = 0;

    sub($byte) {
        warn $byte;
        $num = $byte + ($num << 8);
        warn $num;
        --$size ? __SUB__ : $num;
    }
}

sub gen_array16 {
    my $size = read_n_bytes_as_int(2);

    sub($byte) {
        $size = $size->($byte);

        is_gen($size) ? __SUB__ : gen_array($size);
    };
}

sub gen_nil {
    \my $undef;
}

sub gen_new_value { 
    sub ($byte) { $MessagePackGenerator->assert_coerce($byte); } 
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

sub gen_positive_fixint { \$_  }

sub gen_fixarray {
    gen_array( $_ - 0x90 );
}

sub gen_fixmap {
    gen_map($_ - 0x80);
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
