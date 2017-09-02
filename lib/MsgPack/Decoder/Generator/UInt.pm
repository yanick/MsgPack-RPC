package MsgPack::Decoder::Generator::UInt;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has size => ( required => 1 );

has '+bytes' => sub { $_[0]->size };

sub gen_value {
    my $self = shift;

    $self->buffer_as_int;
};

1;
