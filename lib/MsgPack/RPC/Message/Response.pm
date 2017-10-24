package MsgPack::RPC::Message::Response;

use strict;
use warnings;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::RPC::Message';

has id => ( required => 1 );

has result => ();

has error => ();

sub is_error { !!$_[0]->error }

sub pack {
    my $self = shift;
    return [ 1, $self->id, $self->error, $self->result ];
}

sub is_response { 1}

1;
