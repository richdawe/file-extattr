#!perl -T -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-xattr.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

# XXX: Refactor the common bits between this and 11basic.t
# into Test::Class classes?

use strict;
use Test::More tests => 16;
use File::Temp qw(tempfile);
use File::ExtAttr qw(setfattr getfattr delfattr);
use IO::File;

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );
close $fh || die "can't close $filename $!";

#todo: try wierd characters in here?
#     try unicode?
my $key = "alskdfjadf2340zsdflksjdfa09eralsdkfjaldkjsldkfj";
my $longval = 'A' x $File::ExtAttr::MAX_INITIAL_VALUELEN;
my $longval2 = 'A' x ($File::ExtAttr::MAX_INITIAL_VALUELEN + 11);

##########################
#  Filename-based tests  #
##########################

print "# using $filename\n";

#for (1..30000) { #checking memory leaks
   #check a really big one, bigger than $File::ExtAttr::MAX_INITIAL_VALUELEN
   #Hmmm, 3991 is the biggest number that doesn't generate "no space left on device"
   #on my /var partition, and 920 is the biggest for my loopback partition.
   #What's up with that?
   #setfattr($filename, "$key-2", ('x' x 3991)) || die "setfattr failed on $filename: $!"; 
   setfattr($filename, "$key", $longval)
      || die "setfattr failed on $filename: $!"; 

   #set it
   is (setfattr($filename, "$key", $longval), 1);

   #read it back
   is (getfattr($filename, "$key"), $longval);

   #delete it
   ok (delfattr($filename, "$key"));

   #check that it's gone
   is (getfattr($filename, "$key"), undef);

   #set it
   is (setfattr($filename, "$key", $longval2), 1);

   #read it back
   is (getfattr($filename, "$key"), $longval2);

   #delete it
   ok (delfattr($filename, "$key"));

   #check that it's gone
   is (getfattr($filename, "$key"), undef);
#}
#print STDERR "done\n";
#<STDIN>;

##########################
# IO::Handle-based tests #
##########################

$fh = new IO::File("<$filename") || die "Unable to open $filename";

print "# using file descriptor ".$fh->fileno()."\n";

#for (1..30000) { #checking memory leaks
   #check a really big one, bigger than $File::ExtAttr::MAX_INITIAL_VALUELEN
   #Hmmm, 3991 is the biggest number that doesn't generate "no space left on device"
   #on my /var partition, and 920 is the biggest for my loopback partition.
   #What's up with that?
   #setfattr($filename, "$key-2", ('x' x 3991)) || die "setfattr failed on $filename: $!"; 
   setfattr($fh, "$key", $longval)
    || die "setfattr failed on file descriptor ".$fh->fileno().": $!"; 

   #set it
   is (setfattr($fh, "$key", $longval), 1);

   #read it back
   is (getfattr($fh, "$key"), $longval);

   #delete it
   ok (delfattr($fh, "$key"));

   #check that it's gone
   is (getfattr($fh, "$key"), undef);

   #set it
   is (setfattr($fh, "$key", $longval2), 1);

   #read it back
   is (getfattr($fh, "$key"), $longval2);

   #delete it
   ok (delfattr($fh, "$key"));

   #check that it's gone
   is (getfattr($fh, "$key"), undef);
#}
#print STDERR "done\n";
#<STDIN>;

END {unlink $filename if $filename};
