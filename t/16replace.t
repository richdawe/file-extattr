#!perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-xattr.t'

##########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use Test::More;

BEGIN {
  my $tlib = $0;
  $tlib =~ s|/[^/]*$|/lib|;
  push(@INC, $tlib);
}
use t::Support;

if (t::Support::should_skip()) {
  plan skip_all => 'Tests unsupported on this OS/filesystem';
} else {
  plan tests => 10;
}

use File::Temp qw(tempfile);
use File::ExtAttr qw(setfattr getfattr delfattr);
use IO::File;

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );

close $fh || die "can't close $filename $!";

#todo: try wierd characters in here?
#     try unicode?
my $key = "alskdfjadf2340zsdflksjdfa09eralsdkfjaldkjsldkfj";
my $val = "ZZZadlf03948alsdjfaslfjaoweir12l34kealfkjalskdfas90d8fajdlfkj./.,f";

##########################
#  Filename-based tests  #
##########################

print "# using $filename\n";

#create it
is (setfattr($filename, "$key", $val, { create => 1 }), 1);

#replace it
is (setfattr($filename, "$key", $val, { replace => 1 }), 1);

#read it back
is (getfattr($filename, "$key"), $val);

#delete it
ok (delfattr($filename, "$key"));

#check that it's gone
is (getfattr($filename, "$key"), undef);

##########################
# IO::Handle-based tests #
##########################

$fh = new IO::File("<$filename") || die "Unable to open $filename";

print "# using file descriptor ".$fh->fileno()."\n";

#create it
is (setfattr($fh, "$key", $val, { create => 1 }), 1);

#replace it
is (setfattr($fh, "$key", $val, { replace => 1 }), 1);

#read it back
is (getfattr($fh, "$key"), $val);

#delete it
ok (delfattr($fh, "$key"));

#check that it's gone
is (getfattr($fh, "$key"), undef);

END {unlink $filename if $filename};
