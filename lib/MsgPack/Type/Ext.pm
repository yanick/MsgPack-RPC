package MsgPack::Type::Ext;

use strict;
use warnings;

use Moose;

has "type" => (
    isa => 'Int',
    is => 'ro',
    required => 1,
);

has "data" => (
    is => 'ro',
    required => 1,
);

has fix => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        length($self->data) < 16;
    },
);

has size => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        if ( $self->fix ) {
            my $size = 0;
            $size++ while 2**$size < length $self->data;
            return 2**$size;
            
        }

        return length $self->data;
    },
);

sub padded_data {
    my $self = shift;

    my $size = $self->size;

    my $data = $self->data;
    return join '', ( chr(0) ) x ($size - length $data), $data;
}


1;



