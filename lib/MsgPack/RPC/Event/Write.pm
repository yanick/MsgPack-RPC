package MsgPack::RPC::Event::Write;

use Moose;

extends 'Beam::Event';

has payload => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->message->pack
    },
);

has message => (
    is => 'ro',
);

sub encoded {
    my $self = shift;
    
    MsgPack::Encoder->new(struct => $self->payload)->encoded;
}

1;
