#!perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-xattr.t'

##########################

# Test an explicitly empty namespace

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
  plan tests => 8;
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

#set it - should fail
undef $@;
eval { setfattr($filename, "$key", $val, { namespace => '' }); };
isnt ($@, undef);

#read it back - should be missing
is (getfattr($filename, "$key", { namespace => '' }), undef);

#delete it - should fail
is (delfattr($filename, "$key", { namespace => '' }), 0);

#check that it's gone
is (getfattr($filename, "$key", { namespace => '' }), undef);

##########################
# IO::Handle-based tests #
##########################

$fh = new IO::File("<$filename") || die "Unable to open $filename";

print "# using file descriptor ".$fh->fileno()."\n";

undef $@;
eval { setfattr($fh->fileno(), "$key", $val, { namespace => '' }); };
isnt ($@, undef);

#read it back - should be missing
is (getfattr($fh->fileno(), "$key", { namespace => '' }), undef);

#delete it - should fail
is (delfattr($fh->fileno(), "$key", { namespace => '' }), 0);

#check that it's gone
is (getfattr($fh->fileno(), "$key", { namespace => '' }), undef);

END {unlink $filename if $filename};
