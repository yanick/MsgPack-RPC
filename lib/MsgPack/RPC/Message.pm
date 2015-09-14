package MsgPack::RPC::Message;

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


1;


