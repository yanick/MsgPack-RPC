package MsgPack::Decoder::Generator::Nil;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has '+bytes' => sub { 0 };

has 'push_decoded' => (
    trigger => sub { $_[0]->push_decoded->(undef) },
);

1;
