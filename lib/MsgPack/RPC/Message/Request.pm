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

Returns a L<Promises::Deferred> that, once fulfilled, sends the response back with the provided arguments.

    $rpc->subscribe( something => sub {
        my $request = shift;
        $request->response->resolve('a-okay');
    });

=head2 resp($args)

Shortcut for

    $request->response->resolve($args)

=head2 error($args)

Shortcut for

    $request->response->reject($args)

=cut

use strict;
use warnings;

use MsgPack::RPC::Message::Response;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::RPC::Message::Notification';

use Promises qw/ deferred /;

my $ID = 0;

has id => (
    is => 'ro',
    isa => 'Int',
    lazy => 1,
    default => sub { ++$ID },
);

sub response {
    my $self = shift;
    
    MsgPack::RPC::Message::Response->new(
        id => $self->id,
        result => shift,
    );
}

sub response_error {
    my $self = shift;
    
    MsgPack::RPC::Message::Response->new(
        id => $self->id,
        error => shift,
    );
}

sub is_request { 1}
sub is_notification { 0}

sub pack {
    my $self = shift;
    
    return [ 0, $self->id, $self->method, $self->params ];
}

1;
