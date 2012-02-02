use strict;
use warnings;
use lib 't/lib';

use HTTP::Request::Common;
use Test::More tests => 4;
use Plack::Builder;
use Plack::Test;

my $BODY_READ_LEN = 1024;

my @bodies;

my $app = sub {
    my ( $env ) = @_;

    my $input = $env->{'psgi.input'};
    my $body  = '';
    my $buf   = '';

    while($input->read($buf, $BODY_READ_LEN)) {
        $body .= $buf;
    }

    return [
        200,
        [
            'Content-Type'   => 'application/octet-stream',
            'Content-Length' => length($body),
        ],
        [ $body ],
    ];
};

my $wrapped_app = builder {
    enable 'DumbBodyTracker', storage => \@bodies;
    $app;
};

test_psgi $wrapped_app, sub {
    my ( $cb ) = @_;

    my $res;

    $res = $cb->(GET '/');
    is_deeply \@bodies, [];
    is $res->content, '';

    @bodies = ();

    $res = $cb->(POST '/', Content => 'Lots of content!');
    is_deeply \@bodies, ['Lots of content!'];
    is $res->content, 'Lots of content!';
}
