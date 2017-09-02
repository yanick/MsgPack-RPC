package MsgPack::Decoder::Generator::Int;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has size => ( required => 1,);

has '+bytes' => sub { $_[0]->size };

my @size_format = qw/ c s x l x x x q /; 

sub gen_value {
    my $self = shift;

    my $format = $size_format[ $self->bytes -1 ] ;

    return unpack $format.'*', $self->buffer;
};

1;
