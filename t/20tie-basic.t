#!perl -T

use strict;
use Test::More tests => 5;
use File::Temp qw(tempfile);
use File::ExtAttr::Tie;

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );

close $fh || die "can't close $filename $!";

my %extattr;
my @ks;

tie %extattr, 'File::ExtAttr::Tie', $filename; # ok()?

# Check there are no user extattrs; ignore SELinux security extattrs.
@ks = grep { !/^security\./ } keys(%extattr);
ok(scalar(@ks) == 0);

# Check that creation works.
my $k = 'foo';
my $v = '123';

$extattr{$k} = $v;
is(getfattr($filename, "user.$k"), $v);

# Check that updating works.
$extattr{$k} = "$v$v";
is(getfattr($filename, "user.$k"), "$v$v");

$extattr{$k} = $v;
is(getfattr($filename, "user.$k"), $v);

# Check that deletion works.
delete $extattr{$k};
is(getfattr($filename, "user.$k"), undef);

END {unlink $filename if $filename};
