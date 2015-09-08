use 5.20.0;

use strict;
use warnings;

use Test::More tests => 1;

use MessagePack::RPC;

use experimental 'signatures';

open my $input_fh,  '<',  \my $input;
open my $output_fh, '>>', \my $output;

my $rpc = MessagePack::RPC->new(
    io => [ $input, $output ],
);

$rpc->request( 'method' => [ qw/ param1 param2 / ] );

is $output => 'TBD', "request encapsulated";

$output = undef;

$rpc->notify( 'psst' => [ qw/ param3 param4 / ] );

is $output => 'TBD', "notification";

$input = "request";

$rpc->loop(1);

pass "okay";

subtest 'request -> reply' => sub {
    $rpc->subscribe( my_request => sub ($msg) {
        $msg->reply( 'okay' );
    });

    $input = "send  my request";

    $rpc->loop(1);

    is $output => 'okay';
};


