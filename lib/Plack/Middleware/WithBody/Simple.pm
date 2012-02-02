package Plack::Middleware::WithBody::Simple;

use strict;
use warnings;
use parent 'Plack::Middleware::WithBody';

sub get_request_chunk_callback {
    my ( $self ) = @_;

    my @body_chunks;

    return sub {
        my ( $chunk ) = @_;

        if(defined $chunk) {
            push @body_chunks, $chunk;
        } else {
            $self->on_request_body(join('', @body_chunks));
        }
    };
}

sub get_response_chunk_callback {
    my ( $self ) = @_;

    my @body_chunks;

    return sub {
        my ( $chunk ) = @_;

        if(defined $chunk) {
            push @body_chunks, $chunk;
        } else {
            $self->on_response_body(join('', @body_chunks));
        }
    };
}

sub want_request_body {
    my ( $self ) = @_;

    return $self->can('on_request_body');
}

sub want_response_body {
    my ( $self ) = @_;

    return $self->can('on_response_body');
}

1;

__END__

=head1 SYNOPSIS

  package MyMiddleware;

  use strict;
  use warnings;
  use parent 'Plack::Middleware::WithBody::Simple';

  # implement me only if you care about the request body
  sub on_request_body {
    my ( $self, $body ) = @_;

    # $body is a scalar containing the full request body
    # this method will not be invoked if there is no body!
  }

  # implement me only if you care about the response body
  sub on_response_body {
    my ( $self, $body ) = @_;

    # $body is a scalar containing the full response body
    # this method will not be invoked if there is no body!
  }

=head1 DESCRIPTION

Plack::Middleware::WithBody::Simple is a subclass of
L<Plack::Middleware::WithBody> that just slurps request
and response bodies into a single scalar and passes it
to the L</on_request_body> or L</on_response_body> method,
respectively.  If you subclass this middleware, you don't need
to override both methods; only the one(s) you are interested in.

=head1 METHODS

=head2 $self->on_request_body($body)

Called with the full request body.

=head2 $self->on_response_body($body)

Called with the full response body.

=head1 SEE ALSO

L<Plack::Middleware::WithBody>

=cut
