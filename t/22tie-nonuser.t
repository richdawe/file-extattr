#!perl -w

use strict;
use Test::More;
use POSIX qw/setlocale LC_ALL/;

BEGIN {
  my $tlib = $0;
  $tlib =~ s|/[^/]*$|/lib|;
  push(@INC, $tlib);
}
use t::Support;

if (t::Support::should_skip()) {
  plan skip_all => 'Tests unsupported on this OS/filesystem';
} else {
  plan tests => 40;
}

use File::Temp qw(tempfile);
use File::Path;
use File::ExtAttr::Tie;
use File::ExtAttr qw(getfattr);

# Use the C locale, so all warnings are in the language we are expecting.
setlocale(LC_ALL, 'C');

# Snaffle away the warnings for later analysis.
my $warning;
$SIG{'__WARN__'} = sub { $warning = $_[0] };

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );

close $fh or die "can't close $filename $!";

# Create a directory.
my $dirname = "$filename.dir";
eval { mkpath($dirname); };
if ($@) {
    warn "Couldn't create $dirname: $@";
}

foreach ( $filename, $dirname ) {
    print "# using $_\n";

    my %extattr;
    my @ks;

    tie %extattr, 'File::ExtAttr::Tie', $_, { namespace => 'nonuser' }; # ok()?

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
        is ($warning =~ /(Operation not supported|No such file or directory|Attribute not found)/, 1);
        is(getfattr($_, "$k"), undef);

        # Check that updating works.
        $extattr{$k} = "$v$v";
        is ($warning =~ /(Operation not supported|No such file or directory|Attribute not found)/, 1);
        is(getfattr($_, "$k"), undef);

        $extattr{$k} = $v;
        is ($warning =~ /(Operation not supported|No such file or directory|Attribute not found)/, 1);
        is(getfattr($_, "$k"), undef);

        # Check that deletion works.
        delete $extattr{$k};
        is(getfattr($_, "$k"), undef);
    }

    # Recreate the keys and check that they're all in the hash.

    foreach $k (sort(keys(%test_attrs)))
    {
        my $v = $test_attrs{$k};

        # Check that creation works.
        $extattr{$k} = $v;
        is ($warning =~ /(Operation not supported|No such file or directory|Attribute not found)/, 1);
        is(getfattr($_, "$k"), undef);
    }

    # Check there are only our extattrs.
    @ks = keys(%extattr);
    ok(scalar(@ks) == 0);
    print '# '.join(' ', @ks)."\n";
}

END {
    unlink $filename if $filename;
    rmdir $dirname if $dirname;
};
