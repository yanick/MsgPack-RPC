package MsgPack::Decoder::Generator::Str;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has '+bytes' => (
    trigger => sub {
        my ( $self, $value ) = @_;
        $self->push_decoded->('') unless $value;
    }
);

sub BUILDARGS {
    my( undef, %args ) = @_;
    $args{bytes} ||= $args{size} || 0;
    return \%args;
}

sub gen_value {
    my $self = shift;

    return $self->buffer;
};

1;
