use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'TAPER' }

my $res = request('/');

while ( $res->is_redirect ) {
   $res = request( $res->header('location') );
}

ok( $res->is_success, 'Request should succeed' );
