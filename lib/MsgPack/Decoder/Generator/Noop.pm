package MsgPack::Decoder::Generator::Noop;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has '+bytes' => sub { 0 };

1;
