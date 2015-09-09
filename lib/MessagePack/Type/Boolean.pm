package MessagePack::Type::Boolean;

use strict;
use warnings;

use Moose;

use overload 'bool' => sub {
    $_[0]->value;
},
    fallback => 1;

has "value" => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
);

sub BUILDARGS {
    my( $self, @args ) = @_;
    unshift @args, 'value' if @args == 1;

    return { @args };
}

1;


