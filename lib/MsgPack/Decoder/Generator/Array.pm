package MsgPack::Decoder::Generator::Array;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has size => ( required => 1,);

has values => (
    isa => 'ArrayRef',
    lazy => 1,
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        push_value => 'push',
        nbr_values => 'count',
    },
);

has '+bytes' => sub { 0 };

has is_map => sub { 0 };

has '+next' => sub {
    my $self = shift;

    my $size= $self->size;
    $size *= 2 if $self->is_map;

    unless( $size ) {
        $self->push_decoded->( $self->is_map ? {} : [] );
        return [];
    }

    my @array;

    my @next = ( ( ['Any', push_decoded => sub { 
        push @array, @_; 
        $self->push_decoded->( $self->is_map ? { @array } : \@array) if @array == $size;
    } ] ) x $size,
        [ 'Noop', push_decoded => $self->push_decoded  ] ); 

    return \@next;
};

1;
