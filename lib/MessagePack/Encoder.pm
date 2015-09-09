package MessagePack::Encoder;
# ABSTRACT: Encode a structure into a MessagePack binary string

=head1 SYNOPSIS

    use MessagePack::Encoder;

    my $binary = MessagePack::Encoder->new( struct => [ "hello world" ] );

    use MessagePack::Decoder;

    my $struct = MessagePack::Decoder->new->read_all($binary);

=cut

use strict;
use warnings;

use Moose;

use experimental 'postderef';

use overload '""' => \&encoded;

use Types::Standard qw/ Str ArrayRef Ref Int Any InstanceOf Undef HashRef /;
use Type::Tiny;


my $PositiveFixInt = Type::Tiny->new(
    parent => Int,
    name => 'PositiveFixint',
    constraint => sub { $_ >= 0 and $_ < (2**8)-1 },
);

my $NegativeFixInt = Type::Tiny->new(
    parent => Int,
    name => 'NegativeFixint',
    constraint => sub { $_ < 0 and $_ > 2**5 },
);

my $Str8 = Type::Tiny->new(
    parent => Str,
    name => 'Str8',
    constaints => sub { length $_ <= 2**8 - 1 }
);

my $FixStr = Type::Tiny->new(
    parent => $Str8,
    name => 'FixStr',
    constaints => sub { length $_ <= 31 }
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
    parent => InstanceOf['MessagePack::Type::Boolean'],
    name => 'Boolean'
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


