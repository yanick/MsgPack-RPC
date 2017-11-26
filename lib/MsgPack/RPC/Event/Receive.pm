package MsgPack::RPC::Event::Receive;

use Moose;

extends 'Beam::Event';

has message => (
    is => 'ro',
    required => 1,
    handles => [ qw/ id is_request is_response is_notification params method all_params / ],
);

sub resp {
    my $self = shift;

    $self->emitter->send_response( $self->id, shift );
}

sub error {
    my $self = shift;

    $self->emitter->send_response_error( $self->id, shift );
}

1;
