package MsgPack::Decoder::Generator::FixInt;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has '+bytes' => sub { 1 };

has negative => sub { 0 };

sub gen_value {
    my $self = shift;

    return $self->negative ? 0xe0 - $self->buffer_as_int : $self->buffer_as_int;
}

1;
