package MsgPack::Decoder::Generator::Ext;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has size => ( required => 1,);

has '+bytes' => sub { 1 + $_[0]->size };

sub gen_value {
    my $self = shift;

    my $data = $self->buffer;

    my $type = ord substr $data, 0, 1, '';

    MsgPack::Type::Ext->new(
        fix  => 1,
        size => $self->size,
        data => $data,
        type => $type,
    );
};

1;
