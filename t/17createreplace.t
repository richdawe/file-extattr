#!perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-xattr.t'

##########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 4;
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

#create and replace it -- should fail
undef $@;
eval { setfattr($filename, "$key", $val, { create => 1, replace => 1 }); };
isnt ($@, undef);

#check that it's not been created
is (getfattr($filename, "$key"), undef);

##########################
# IO::Handle-based tests #
##########################

$fh = new IO::File("<$filename") || die "Unable to open $filename";

print "# using file descriptor ".$fh->fileno()."\n";

my $key2 = $key.'2';

#create and replace it -- should fail
undef $@;
eval { setfattr($fh, $key2, $val, { create => 1, replace => 1 }); };
isnt ($@, undef);

#check that it's not been created
is (getfattr($fh, $key2), undef);

END {unlink $filename if $filename};
