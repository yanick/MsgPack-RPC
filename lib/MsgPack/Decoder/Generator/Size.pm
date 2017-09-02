package MsgPack::Decoder::Generator::Size;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has next_item => (
    is => 'ro',
    required => 1,
);

has '+next' => sub {
    my $self = shift;
    my $next = $self->next_item;
    return [[ (ref $next ? @$next : $next), size => $self->buffer_as_int ]];
};

1;
