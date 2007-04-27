#!perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-xattr.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 4;
use File::Temp qw(tempfile);
use File::ExtAttr qw(setfattr getfattr delfattr);

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );
close $fh || die "can't close $filename $!";


print "# using $filename\n";

#todo: try wierd characters in here?
#     try unicode?
my $key = "alskdfjadf2340zsdflksjdfa09eralsdkfjaldkjsldkfj";
my $val = "ZZZadlf03948alsdjfaslfjaoweir12l34kealfkjalskdfas90d8fajdlfkj./.,f";

#for (1..30000) { #checking memory leaks

   #will die if xattr stuff doesn't work at all
   setfattr($filename, "$key", $val) || die "setfattr failed on $filename: $!"; 

   #set it
   is (setfattr($filename, "$key", $val), 1);

   #read it back
   is (getfattr($filename, "$key"), $val);

   #delete it
   ok (delfattr($filename, "$key"));

   #check that it's gone
   is (getfattr($filename, "$key"), undef);
#}
#print STDERR "done\n";
#<STDIN>;

END {unlink $filename if $filename};
