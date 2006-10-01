#!perl -T -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-xattr.t'

##########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 12;
use File::Temp qw(tempfile);
use File::ExtAttr qw(setfattr getfattr delfattr listfattrns);
use IO::File;

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );

close $fh || die "can't close $filename $!";

#todo: try wierd characters in here?
#     try unicode?
my $key = "alskdfjadf2340zsdflksjdfa09eralsdkfjaldkjsldkfj";
my $val = "ZZZadlf03948alsdjfaslfjaoweir12l34kealfkjalskdfas90d8fajdlfkj./.,f";

my @ns;

##########################
#  Filename-based tests  #
##########################

print "# using $filename\n";

#for (1..30000) { #checking memory leaks

   #will die if xattr stuff doesn't work at all
   setfattr($filename, "$key", $val, { namespace => 'user' })
     || die "setfattr failed on filename $filename: $!"; 

   #set it
   is (setfattr($filename, "$key", $val, { namespace => 'user' }), 1);

   #check user namespace exists now
   @ns = listfattrns($filename);
   is (grep(/^user$/, @ns), 1);

   #read it back
   is (getfattr($filename, "$key", { namespace => 'user' }), $val);

   #delete it
   ok (delfattr($filename, "$key", { namespace => 'user' }));

   #check that it's gone
   is (getfattr($filename, "$key", { namespace => 'user' }), undef);

   #check user namespace doesn't exist now
   @ns = listfattrns($filename);
   is (grep(/^user$/, @ns), 0);
#}
#print STDERR "done\n";
#<STDIN>;

##########################
# IO::Handle-based tests #
##########################

$fh = new IO::File("<$filename") || die "Unable to open $filename";

print "# using file descriptor ".$fh->fileno()."\n";

#for (1..30000) { #checking memory leaks

   #will die if xattr stuff doesn't work at all
   setfattr($fh, "$key", $val, { namespace => 'user' })
     || die "setfattr failed on file descriptor ".$fh->fileno().": $!"; 

   #set it
   is (setfattr($fh, "$key", $val, { namespace => 'user' }), 1);

   #check user namespace exists now
   @ns = listfattrns($fh);
   is (grep(/^user$/, @ns), 1);

   #read it back
   is (getfattr($fh, "$key", { namespace => 'user' }), $val);

   #delete it
   ok (delfattr($fh, "$key", { namespace => 'user' }));

   #check that it's gone
   is (getfattr($fh, "$key", { namespace => 'user' }), undef);

   #check user namespace doesn't exist now
   @ns = listfattrns($fh);
   is (grep(/^user$/, @ns), 0);
#}
#print STDERR "done\n";
#<STDIN>;

END {unlink $filename if $filename};
