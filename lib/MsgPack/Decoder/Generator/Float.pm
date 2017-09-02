package MsgPack::Decoder::Generator::Float;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has size => ( required => 1,);

has '+bytes' => sub { $_[0]->size };

sub gen_value {
    my $self = shift;

    my $format = $self->size == 4 ? 'f' : 'd';

    return unpack $format, $self->buffer;
};

1;
