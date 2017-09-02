package MsgPack::Decoder::Generator::String;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has '+gen_value' => sub {
    my $self = shift;
    $self->buffer;
};

1;
