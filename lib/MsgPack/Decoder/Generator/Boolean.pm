package MsgPack::Decoder::Generator::Boolean;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has '+bytes' => sub { 1 };

sub gen_value {
    my $self = shift;
    MsgPack::Type::Boolean->new( $self->buffer_as_int - 0xc2);
}

1;
