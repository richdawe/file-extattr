#!perl -w

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
  plan tests => 12;
}

use File::Temp qw(tempfile);
use File::ExtAttr::Tie;
use File::ExtAttr qw(getfattr);

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );

close $fh || die "can't close $filename $!";

my %extattr;
my @ks;

tie %extattr, 'File::ExtAttr::Tie', $filename; # ok()?

# Check there are no user extattrs.
@ks = keys(%extattr);
ok(scalar(@ks) == 0);

# Test multiple attributes.
my %test_attrs = ( 'foo' => '123', 'bar' => '456' );
my $k;

foreach $k (sort(keys(%test_attrs)))
{
    my $v = $test_attrs{$k};

    # Check that creation works.
    $extattr{$k} = $v;
    is(getfattr($filename, "$k"), $v);

    # Check that updating works.
    $extattr{$k} = "$v$v";
    is(getfattr($filename, "$k"), "$v$v");

    $extattr{$k} = $v;
    is(getfattr($filename, "$k"), $v);

    # Check that deletion works.
    delete $extattr{$k};
    is(getfattr($filename, "$k"), undef);
}

# Recreate the keys and check that they're all in the hash.

foreach $k (sort(keys(%test_attrs)))
{
    my $v = $test_attrs{$k};

    # Check that creation works.
    $extattr{$k} = $v;
    is(getfattr($filename, "$k"), $v);
}

# Check there are only our extattrs.
@ks = keys(%extattr);
ok(scalar(@ks) == scalar(keys(%test_attrs)));
print '# '.join(' ', @ks)."\n";

END {unlink $filename if $filename};
