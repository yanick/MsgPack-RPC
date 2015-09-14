use strict;
use warnings;

use Test::More tests => 12;
use Test::Deep;

use MsgPack::Encoder;
use MsgPack::Decoder;
use MsgPack::Type::Boolean;
use MsgPack::Type::Ext;

my %structs = (
    fixint  => 0,
    negfixint => -5,
    fixint2 => 15,
    nil => undef,
    fixarray => [ 1..10 ],
    fixmap => { 1..10 },
    fixstr => "hello",
    ext1 => MsgPack::Type::Ext->new( type => 5, data => chr(13) ),
    'mix' => [0, 4, "vim_eval", ["call rpcrequest( nvimx_channel, \"foo\", \"dummy\" )"]],
    'some string' => "call rpcrequest( nvimx_channel, \"foo\", \"dummy\" )",
    'int8' => -128,
);

my $decoder = MsgPack::Decoder->new( log_to_stderr => 0, debug => 0 );

while ( my( $name, $struct ) = each %structs ) {
    $decoder->read( MsgPack::Encoder->new(  struct => $struct )->encoded );
    cmp_deeply $decoder->next => $struct, $name;
}

subtest booleans => sub {
    for ( 0..1 ) {
        $decoder->read( MsgPack::Encoder->new( struct => MsgPack::Type::Boolean->new($_) ) );
        my $next = $decoder->next;
        isa_ok $next => 'MsgPack::Type::Boolean';
        ok !!$next == $_;
    }
};


