## no critic (RequireUseStrict)
package Plack::Middleware::WithBody;

## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Plack::Middleware'; # XXX should this be a Plack::Component instead? it'd be nice to be able to write easy
                                #     applications that access the body

use Fcntl qw(SEEK_SET);
use File::Temp;

my $CHUNK_SIZE = 1024;

sub call {
    my ( $self, $env ) = @_;

    my $app = $self->app;

    if($self->want_request_body) {
        $self->invoke_request_handler($env);
    }

    my $res = $app->($env);

    if($self->want_response_body) {
        $res = $self->invoke_response_handler($res);
    }

    return $res;
}

sub invoke_request_handler {
    my ( $self, $env ) = @_;

    return unless $env->{'CONTENT_LENGTH'} || 0 > 0;

    my $input    = $env->{'psgi.input'};
    my $callback = $self->get_request_chunk_callback;

    if($input->can('seek')) {
        my $buffer = '';
        my $bytes;

        while($bytes = $input->read($buffer, $CHUNK_SIZE)) {
            $callback->($buffer);
        }
        unless(defined $bytes) {
            # XXX handle error
        }
        $input->seek(0, SEEK_SET);
    } else {
        my $new_handle = File::Temp->new;
        $env->{'psgi.input'} = $new_handle;

        my $buffer = '';
        my $bytes;

        while($bytes = $input->read($buffer, $CHUNK_SIZE)) {
            $callback->($buffer);
            $new_handle->write($buffer); # XXX error handling
        }
        unless(defined $bytes) {
            # XXX handle error
        }

        $new_handle->seek(0, SEEK_SET);
    }
    $callback->(undef);
}

sub handle_basic_body {
    my ( $self, $res, $callback ) = @_;

    my $body = $res->[2];

    if(ref($body) eq 'ARRAY') {
        foreach my $chunk (@$body) {
            $callback->($chunk);
        }
    } else { # IO::Handle-like object
        my $new_body = File::Temp->new;
        $res->[2]    = $new_body;

        local $/ = \$CHUNK_SIZE;

        while(my $line = $body->getline) {
            $callback->($line);
            $new_body->write($line);
        }
        $body->close;
    }

    $callback->(undef);
}

sub invoke_response_handler {
    my ( $self, $res ) = @_;

    my $callback = $self->get_response_chunk_callback;

    if(ref($res) eq 'CODE') {
        return sub {
            my ( $respond ) = @_;

            $res->(sub {
                my ( $response ) = @_;
                my $body         = $response->[2];

                if($body) {
                    $self->handle_basic_body($response, $callback);
                    $respond->($response);
                } else {
                    my $writer = $respond->($response);

                    return sub {
                        my ( $chunk ) = @_;

                        $callback->($chunk); # XXX how will we signal EOS?
                        $writer->($chunk);
                    };
                }
            });
        };
    } else {
        $self->handle_basic_body($res, $callback);
        return $res;
    }
}

sub want_request_body {
    return 0;
}

sub want_response_body {
    return 0;
}

1;

__END__

# ABSTRACT:  A short description of Plack::Middleware::WithBody

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=head1 SEE ALSO

=cut
