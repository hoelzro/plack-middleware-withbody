package Plack::Middleware::DumbBodyTracker;

use strict;
use warnings;
use parent 'Plack::Middleware::WithBody::Simple';

use Plack::Util::Accessor qw(storage);

sub on_request_body {
    my ( $self, $body ) = @_;

    push @{ $self->storage }, $body;
}

1;
