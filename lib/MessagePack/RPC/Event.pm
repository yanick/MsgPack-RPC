package Neovim::RPC::Event;
use Moose;
extends 'Beam::Event';

has args => (
   traits => [ 'Array' ],
   is => 'ro',
   default => sub { [] },
   handles => {
      all_args => 'elements',
   },
);

has event_id => (
    is => 'ro',
);

sub reply {
    my $self = shift;

    $self->emitter->send([ 1, $self->event_id, undef, shift ]
    );
}

1;
