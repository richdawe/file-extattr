#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Linux::xattr' );
}

diag( "Testing Linux::xattr $Linux::xattr::VERSION, Perl $], $^X" );
