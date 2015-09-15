package MsgPack::RPC::Message::Request;
# ABSTRACT: a MessagePack-RPC request

=head1 SYNOPSIS

    use MsgPack::RPC;

    my $rpc = MsgPack::RPC->new( io => '127.0.0.1:6543' );

    $rpc->emit( some_request => 'MsgPack::RPC::Message::Request', args => [ 1..5 ] );

=head1 DESCRIPTION

Sub-class of L<MsgPack::RPC::Message> representing an incoming request.

=head1 METHODS

=head2 new( args => $args, message_id => $id ) 

Accepts the same argument as L<MsgPack::RPC::Message>, plus C<message_id>,
the id of the request.

=head2 response

Returns a L<Future> that, once fulfilled, will send a response back with the provided arguments.

    $rpc->subscribe( something => sub {
        my $request = shift;
        $request->response->done('a-okay');
    });

=head2 done($args)

Shortcut for

    $request->response->done($args)

=head2 fail($args)

Shortcut for

    $request->response->fail($args)

=cut

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
    handles => [ qw/ done fail / ],
);

1;
