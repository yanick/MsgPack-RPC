package MsgPack::RPC::Message;
# ABSTRACT: a MessagePack-RPC notification

=head1 SYNOPSIS

    use MsgPack::RPC;

    my $rpc = MsgPack::RPC->new( io => '127.0.0.1:6543' );

    $rpc->emit( some_notification => 'MsgPack::RPC::Message', args => [ 1..5 ] );

=head1 DESCRIPTION

C<MsgPack::RPC::Message> extends the L<Beam::Event> class, and encapsulates a notification received by 
the L<MsgPack::RPC> object.  Requests are encapsulated by the sub-class L<MsgPack::RPC::Message::Request>.

=head1 METHODS

=head2 new( args => $args )

The constructor accepts a single argument, C<args>, which is the struct 
holding the arguments of the notification itself.

=head1 SEE ALSO

=over

=item L<MsgPack::RPC::Message::Request> - subclass for requests.

=back

=cut

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


