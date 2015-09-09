use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;

use MessagePack::Encoder;

sub encode {
    [ map { ord } split '', MessagePack::Encoder->new(struct => shift) ]
};

sub cmp_encode(@){
    my( $struct, $wanna, $comment ) = @_;
    $struct = encode($struct);
    cmp_deeply( $struct => $wanna, $comment )
        or diag explain $struct;
}

cmp_encode 15 => [ 15 ], "number 15";

