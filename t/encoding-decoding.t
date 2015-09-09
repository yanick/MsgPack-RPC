use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;

use MessagePack::Encoder;
use MessagePack::Decoder;
use MessagePack::Type::Boolean;

my %structs = (
    fixint  => 0,
    negfixint => -5,
    fixint2 => 15,
    nil => undef,
    fixarray => [ 1..10 ],
    fixmap => { 1..10 },
    fixstr => "hello",
);

my $decoder = MessagePack::Decoder->new;

while ( my( $name, $struct ) = each %structs ) {
    $decoder->read( MessagePack::Encoder->new( struct => $struct )->encoded );
    cmp_deeply $decoder->next => $struct, $name;
}

subtest booleans => sub {
    for ( 0..1 ) {
        $decoder->read( MessagePack::Encoder->new( struct => MessagePack::Type::Boolean->new($_) ) );
        my $next = $decoder->next;
        isa_ok $next => 'MessagePack::Type::Boolean';
        ok !!$next == $_;
    }
};


