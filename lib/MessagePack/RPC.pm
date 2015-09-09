package MessagePack::RPC;
# ABSTRACT: MessagePack RPC client

use strict;
use warnings;

use Moose;
use IO::Socket::INET;
use MessagePack::Decoder;
use MessagePack::Encoder;
use MessagePack::RPC::Event;
use Future;

use experimental 'signatures';

with 'Beam::Emitter';
with 'MooseX::Role::Loggable' => {
    -excludes => [ 'Bool' ],
};

has io => (
    required => 1,
    is       => 'ro',
    trigger  => sub($self,$io,@) {
        if( ref $io eq 'ARRAY' ) {
            $self->_io_read(sub{ getc $io->[0] });

            $self->_io_write(sub(@stuff){
                print { $io->[1] } @stuff
                    or die "couldn't write to output\n";
            });
        }
    },
);

has [ qw/ _io_read _io_write / ] => ( is => 'rw' );


has "host" => (
    isa => 'Str',
    is => 'ro',
    lazy => 1,
    default => sub { ( split ':', $_[0]->nvim_listen_address )[0] },
);

has "port" => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub { ( split ':', $_[0]->nvim_listen_address )[1] },
);

has "socket" => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $addie = join ':', $self->host, $self->port;

        IO::Socket::INET->new( $addie )
            or die "couldn't connect to $addie";
    },
);

has decoder => (
    isa => 'MessagePack::Decoder',
    is => 'ro',
    lazy => 1,
    default => sub {
        MessagePack::Decoder->new(
            logger => $_[0]->logger
        );
    },
);

has "response_callbacks" => (
    is => 'ro',
    lazy => 1,
    default => sub {
        {};
    },
);

sub add_responce_callback {
    my( $self, $id ) = @_;
    my $future = Future->new;
    $self->response_callbacks->{$id} = {
        timestamp => time,
        future => $future,
    };

    $future;
}

sub request($self,$method,$args=[],$id=++$MessagePack::RPC::MSG_ID) {
    $self->send([ 0, $id, $method, $args ]);
    $self->add_responce_callback($id);
}

sub notify($self,$method,$args=[]) {
    $self->send([2,$method,$args]);
}

sub send($self,$struct) {
    $self->log( [ "sending %s", $struct] );

    my $encoded = MessagePack::Encoder->new(struct => $struct)->encoded;

    $self->log_debug( [ "encoded: %s", $encoded ] );
    $self->_io_write->($encoded);
}

sub loop {
    my $self = shift;
    my $until = shift;

    while ( my $byte = $self->_io_read->() ) {
        $self->decoder->read( $byte );

        while( $self->decoder->has_buffer ) {
            my $next = $self->decoder->next;
            $self->log( [ "receiving %s" , $next ]);

            if ( $next->[0] == 1 ) {
                $self->log_debug( [ "it's a response for %d", $next->[1] ] );
                if( my $callback =  $self->response_callbacks->{$next->[1]} ) {
                    my $f = $callback->{future};
                    $next->[2] 
                        ? $f->fail($next->[2])
                        : $f->done($next->[3])
                        ;
                }
            }
            elsif( $next->[0] == 2 ) {
                $self->log_debug( [ "it's a '%s' event", $next->[1] ] );
                $self->emit( $next->[1], class => 'Neovim::RPC::Event', args => $next->[2] );     
            }
            elsif( $next->[0] == 0 ) {
                $self->log_debug( [ "it's a '%s' request", $next->[2] ] );
                $self->emit( $next->[2], class => 'Neovim::RPC::Event', args => $next->[3],
                    event_id => $next->[1] );     
            }

            return if $until and not --$until;

        }
    }
}
    

1;



