package MsgPack::Decoder::Generator::ArraySize;

use Moose;
use MooseX::MungeHas 'is_ro';

use experimental 'signatures';

extends 'MsgPack::Decoder::Generator';

has is_map => sub { 0 };

has '+next' => sub($self) {
    return [[ 'Array', size => $self->buffer_as_int, is_map => $self->is_map ]];
};

1;
