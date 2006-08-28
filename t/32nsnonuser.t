#!perl -T
# -*-perl-*-

# Test that creating non-"user."-prefixed attributes fails.
# XXX: Probably Linux-specific

use strict;
use Test::More tests => 4;
use File::Temp qw(tempfile);
use File::ExtAttr qw(setfattr getfattr delfattr);

# Snaffle away the warnings for later analysis.
my $warning;
$SIG{'__WARN__'} = sub { $warning = $_[0] };

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );
close $fh || die "can't close $filename $!";

print "# using $filename\n";

#todo: try wierd characters in here?
#     try unicode?
my $key = "alskdfjadf2340zsdflksjdfa09eralsdkfjaldkjsldkfj";
my $val = "ZZZadlf03948alsdjfaslfjaoweir12l34kealfkjalskdfas90d8fajdlfkj./.,f";

#set it
setfattr($filename, "$key", $val, { namespace => 'nonuser' });
is ($warning =~ /(Operation not supported|No such file or directory)/, 1);

#read it back
is (getfattr($filename, "$key", { namespace => 'nonuser' }), undef);

#delete it
delfattr($filename, "$key", { namespace => 'nonuser' });
is ($warning =~ /(Operation not supported|No such file or directory)/, 1);

#check that it's gone
is (getfattr($filename, "$key", { namespace => 'nonuser' }), undef);

END {unlink $filename if $filename};
