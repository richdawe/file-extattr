# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-xattr.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 6;
use File::Temp qw(tempfile);
BEGIN { use_ok('File::ExtAttr') };

use File::ExtAttr qw(setfattr getfattr delfattr);

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );
close $fh || die "can't close $filename $!";


my $fail = 0;
foreach my $constname (qw(
	XATTR_REPLACE XATTR_CREATE)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined File::ExtAttr macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

print STDERR "using $filename\n";

#todo: try wierd characters in here?
#     try unicode?
my $key = "alskdfjadf2340zsdflksjdfa09eralsdkfjaldkjsldkfj";
my $val = "ZZZadlf03948alsdjfaslfjaoweir12l34kealfkjalskdfas90d8fajdlfkj./.,f";

#for (1..30000) { #checking memory leaks

   #will die if xattr stuff doesn't work at all
   setfattr($filename, "user.$key", $val, 0) || die "setfattr failed on $filename: $!"; 

   #set it
   is (setfattr($filename, "user.$key", $val, 0), 1);

   #read it back
   is (getfattr($filename, "user.$key"), $val);

   #delete it
   ok (delfattr($filename, "user.$key"));

   #check that it's gone
   is (getfattr($filename, "user.$key"), undef);

   #check a really big one, bigger than $File::ExtAttr::MAX_INITIAL_VALUELEN
   #Hmmm, 3991 is the biggest number that doesn't generate "no space left on device"
   #on my /var partition, and 920 is the biggest for my loopback partition.
   #What's up with that?
   #setfattr($filename, "user.$key-2", ('x' x 3991), 0) || die "setfattr failed on $filename: $!"; 
   setfattr($filename, "user.$key-2", ('x' x 920), 0) || die "setfattr failed on $filename: $!"; 
   getfattr($filename, "user.$key-2");

#}
#print STDERR "done\n";
#<STDIN>;

END {unlink $filename if $filename};
