package MsgPack::RPC::Message::Request;

use strict;
use warnings;

use Moose;

use Future;

extends 'MsgPack::RPC::Message';

has message_id => (
    is => 'ro',
);

has response => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $future = Future->new;

        $future->on_done(sub{
            $self->emitter->response($self->message_id,shift);
        });
        $future->on_fail(sub{
            $self->emitter->response_error($self->message_id,shift);
        });

        $future;
    },
);

sub reply {
    my $self = shift;

    $self->emitter->send([ 1, $self->event_id, undef, shift ]
    );
}

1;
