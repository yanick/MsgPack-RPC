package MsgPack::Encoder;
# ABSTRACT: Encode a structure into a MessagePack binary string

=head1 SYNOPSIS

    use MsgPack::Encoder;

    my $binary = MsgPack::Encoder->new( struct => [ "hello world" ] )->encoded;

    use MsgPack::Decoder;

    my $struct = MsgPack::Decoder->new->read_all($binary);

=head1 DESCRIPTION

C<MsgPack::Encoder> objects encapsulate a Perl data structure, and provide
its MessagePack serialization.

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

=head1 OVERLOADING

=head2 Stringification

The stringification of a C<MsgPack::Encoder> object is its MessagePack encoding.


    print MsgPack::Encoder->new( struct => $foo );
    
    # equivalent to

    print MsgPack::Encoder->new( struct => $foo )->encoded;

=head1 METHODS

=head2 new( struct => $perl_struct )

The constructor accepts a single argument, C<struct>, which is the perl structure (or simple scalar)
to encode.

=head2 encoded

Returns the MessagePack representation of the structure.

=cut

use strict;
use warnings;

use Moose;

use experimental 'postderef';

use overload '""' => \&encoded;

use Types::Standard qw/ Str ArrayRef Ref Int Any InstanceOf Undef HashRef /;
use Type::Tiny;

use MsgPack::Type::Ext;


my $PositiveFixInt = Type::Tiny->new(
    parent => Int,
    name => 'PositiveFixint',
    constraint => sub { $_ >= 0 and $_ < 2**8 },
);

my $NegativeFixInt = Type::Tiny->new(
    parent => Int,
    name => 'NegativeFixint',
    constraint => sub { $_ < 0 and $_ > 2**5 },
);

my $Str8 = Type::Tiny->new(
    parent => Str,
    name => 'Str8',
    constaints => sub { length $_ < 2**8 }
);

my $FixStr = Type::Tiny->new(
    parent => $Str8,
    name => 'FixStr',
    constraint => sub { length $_ <= 31 }
);

my $FixArray = Type::Tiny->new(
    parent => ArrayRef,
    name => 'FixArray',
    constraint => sub { @$_ < 31 },
);

my $Nil = Type::Tiny->new(
    parent => Undef,
    name => 'Nil',
);

my $FixMap = Type::Tiny->new(
    parent => HashRef,
    name => 'FixMap',
    constraint => sub { keys %$_ < 16 }
);

my $Boolean = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Boolean'],
    name => 'Boolean'
);

my $FixExt1 = Type::Tiny->new(
    parent => InstanceOf['MsgPack::Type::Ext'],
    name => 'FixExt1',
    constraint => sub { $_->fix and $_->size == 1 },
);


my $MessagePack = Type::Tiny->new(
    parent => InstanceOf['MessagePacked'],
    name => 'MessagePack',
)->plus_coercions(
    $Boolean => \&encode_boolean,
    $PositiveFixInt      ,=> \&encode_positive_fixint,
    $NegativeFixInt      ,=> \&encode_negative_fixint,
    $FixStr ,=> \&encode_fixstr,
    $Str8 ,=> \&encode_str8,
    $FixArray ,=> \&encode_fixarray,
    $Nil => \&encode_nil,
    $FixMap => \&encode_fixmap,
    $FixExt1 => \&encode_fixext1,
);

has struct => (
    isa => $MessagePack,
    is => 'ro',
    required => 1,
    coerce => 1,
);

sub BUILDARGS {
    shift;
    return { @_ == 1 ? ( struct => $_ ) : @_ };
}

sub encoded {
    my $self = shift;
    my $x = $MessagePack->assert_coerce($self->struct);
    return $$x;
}

sub _packed($) {
    my $value = shift;
    bless \$value, 'MessagePacked';
}

sub encode_boolean{
    _packed chr 0xc2 + $_;
}

sub encode_fixmap {
    my @inner = %{ shift @_ };
    
    my $size = @inner/2;

    _packed join '', chr( 0x80 + $size ), map { $$_ } map { $MessagePack->assert_coerce($_) } @inner;
}

sub encode_fixext1 {
    my $ext = shift;
    _packed chr( 0xd4 ) . chr( $ext->type ) . $ext->padded_data;
}

sub encode_str8 {
    my $string = shift;
    _packed chr( 0xd9 ) . chr( length $string ) . $string;
}

sub encode_fixstr {
    my $string = shift;
    _packed chr( 0xa0 + length $string ) . $string;
}

sub encode_positive_fixint {
    my $int = shift;

    _packed chr $int;
}

sub encode_negative_fixint {
    my $int = shift;

    _packed chr( 0xe0 - $int );
}

sub encode_nil {
    _packed chr 0xc0;
}

sub encode_fixarray {
    my @inner = @{ shift @_ };
    
    my $size = @inner;

    _packed join '', chr( 0x90 + $size ), map { $$_ } map { $MessagePack->assert_coerce($_) } @inner;
}


1;


