package MsgPack::Decoder;
# ABSTRACT: Decode data from a MessagePack stream

=head1 SYNOPSIS

    use MsgPack::Decoder;

    use MsgPack::Encoder;
    use Data::Printer;

    my $decoder = MsgPack::Decoder->new;

    my $msgpack_binary = MsgPack::Encoder->new(struct => [ "hello world" ] )->encoded;

    $decoder->read( $msgpack_binary );

    my $struct = $decode->next;  

    p $struct;    # prints [ 'hello world' ]

    
=head2 DESCRIPTION

C<MsgPack::Decoder> objects take in the raw binary representation of 
one or more MessagePack data structures, and convert it back into their
Perl representations.

=head2 METHODS

=cut

use 5.20.0;

use strict;
use warnings;

use Carp;

use MsgPack::Type::Boolean;

use Moose;

use List::AllUtils qw/ reduce first first_index any /;

use experimental 'signatures', 'postderef';

use Log::Any;
has log => (
    is => 'ro',
    lazy =>1,
    default => sub { 
    Log::Any->get_logger->clone( prefix => "[MsgPack::Decoder] ");
});

use MsgPack::Decoder::Generator::Any;

=head3 read( @binary_values ) 

Reads in the raw binary to convert. The binary can be only a partial piece of the 
encoded structures.  If so, all structures that can be decoded will be
made available in the buffer, while the potentially last unterminated structure will
remain "in flight".

Returns how many structures were decoded.

=cut

has generator => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        
        MsgPack::Decoder::Generator::Any->new(
            push_decoded => sub{ $self->add_to_buffer(@_) }
        )
    }
);


sub read($self,@values) {
    my $size = $self->buffer_size;

    $self->generator(
        $self->generator->read( join '', @values )
    );

    return $self->buffer_size - $size;
}


=head3 has_buffer

Returns the number of decoded structures currently waiting in the buffer.

=head3 next

Returns the next structure from the buffer.

    $decoder->read( $binary );

    while( $decoder->has_buffer ) {
        my $next = $decoder->next;
        do_stuff( $next );
    }

Note that the returned structure could be C<undef>, so don't do:

    $decoder->read( $binary );

    # NO! $next could be 'undef'
    while( my $next = $decoder->next ) {
        do_stuff( $next );
    }

=head3 all 

Returns (and flush from the buffer) all the currently available structures.

=cut


has buffer => (
    is => 'rw',
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        'has_buffer' => 'count',
        'buffer_size' => 'count',
        next => 'shift',
        all => 'elements',
        add_to_buffer => 'push',
    },
);

after add_to_buffer => sub {
    my ( $self, @values ) = @_;
    $self->log->debugf( 'pushing to buffer: %s', \@values );
};

after all => sub($self) {
    $self->buffer([]);
};

=head3 read_all( @binaries )

Reads the provided binary data and returns all structures decoded so far.

    
    @data = $decoder->read_all($binary);

    # equivalent to
    
    $decoder->read(@binaries);
    @data = $decoder->all;

=cut

sub read_all($self,@vals){
    $self->read(@vals);
    $self->all;
}

=head3 read_next( @binaries )

Reads the provided binary data and returns the next structure decoded so far.
If there is no data in the buffer, dies.

    $data = $decoder->read_next($binary);

    # roughly equivalent to
    
    $decoder->read(@binaries);
    $data = $decoder->next or die;

=cut

sub read_next($self,@vals){
    $self->read(@vals);
    carp "buffer is empty" unless $self->has_buffer;
    $self->next;
}

1;
