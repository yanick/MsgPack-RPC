package MsgPack::Decoder::Event::Decoded;
# ABSTRACT: MsgPacker::Decoder decoding event 

=head1 DESCRIPTION 

Event emitted by a L<MsgPacker::Decoder> object configured as an emitter
when incoming data structured are decoded.

=head1 METHODS

=head2 payload_list 

Returns a list of all decoded data structures.

=cut

use Moose;
extends 'Beam::Event';

has payload => (
    is => 'ro',
    isa => 'ArrayRef',
    required => 1,
    traits => [ 'Array' ],
    handles => {
        payload_list => 'elements',
    },
);

1;
