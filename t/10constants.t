#!perl -T

# Test that XATTR_* #defines were found and are available.

use strict;
no strict 'refs';
use Test::More tests => 2;
use File::ExtAttr ':all';

SKIP: {
  skip('Create/replace Options not supported on this platform', 2)
    if ($^O =~ /bsd$/i);

  foreach my $constname (qw{XATTR_REPLACE XATTR_CREATE}) {
    eval {
        my $name = "File::ExtAttr::$constname";
        my $a = &$name();
    };

    my $found
        =  ($@ !~ /^Your vendor has not defined/)
        && ($@ !~ /^[A-Za-z_]+ is not a valid/);

    ok($found, "File::ExtAttr macro $constname defined");
  }
}
