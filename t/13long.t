#!perl -T

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-xattr.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

# XXX: Refactor the common bits between this and 11basic.t
# into Test::Class classes?

use strict;
use Test::More tests => 8;
use File::Temp qw(tempfile);
use File::ExtAttr qw(setfattr getfattr delfattr);

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );
close $fh || die "can't close $filename $!";


print "# using $filename\n";

#todo: try wierd characters in here?
#     try unicode?
my $key = "alskdfjadf2340zsdflksjdfa09eralsdkfjaldkjsldkfj";
my $longval = 'A' x $File::ExtAttr::MAX_INITIAL_VALUELEN;
my $longval2 = 'A' x ($File::ExtAttr::MAX_INITIAL_VALUELEN + 11);

#for (1..30000) { #checking memory leaks
   #check a really big one, bigger than $File::ExtAttr::MAX_INITIAL_VALUELEN
   #Hmmm, 3991 is the biggest number that doesn't generate "no space left on device"
   #on my /var partition, and 920 is the biggest for my loopback partition.
   #What's up with that?
   #setfattr($filename, "user.$key-2", ('x' x 3991), 0) || die "setfattr failed on $filename: $!"; 
   setfattr($filename, "user.$key", $longval, 0)
      || die "setfattr failed on $filename: $!"; 

   #set it
   is (setfattr($filename, "user.$key", $longval, 0), 1);

   #read it back
   is (getfattr($filename, "user.$key"), $longval);

   #delete it
   ok (delfattr($filename, "user.$key"));

   #check that it's gone
   is (getfattr($filename, "user.$key"), undef);

   #set it
   is (setfattr($filename, "user.$key", $longval2, 0), 1);

   #read it back
   is (getfattr($filename, "user.$key"), $longval2);

   #delete it
   ok (delfattr($filename, "user.$key"));

   #check that it's gone
   is (getfattr($filename, "user.$key"), undef);
#}
#print STDERR "done\n";
#<STDIN>;

END {unlink $filename if $filename};
