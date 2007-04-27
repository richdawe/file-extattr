#!perl -w

use strict;
use Test::More tests => 122;
use File::Temp qw(tempfile);
use File::ExtAttr qw(setfattr getfattr delfattr listfattr);
use IO::File;

my $TESTDIR = ($ENV{ATTR_TEST_DIR} || '.');
my ($fh, $filename) = tempfile( DIR => $TESTDIR );

close $fh || die "can't close $filename $!";

my %vals;
for (my $i = 0; $i < 10; ++$i)
{
    $vals{"key$i"} = "val$i";
}

##########################
#  Filename-based tests  #
##########################

print "# using $filename\n";

foreach (keys %vals)
{
    # create it
    is (setfattr($filename, $_, $vals{$_}, { create => 1 }), 1);

    # create it again -- should fail
    is (setfattr($filename, $_, $vals{$_}, { create => 1 }), 0);

    # read it back
    is (getfattr($filename, $_), $vals{$_});
}

# Check that the list contains all the attributes.
my @attrs = listfattr($filename);
@attrs = sort @attrs;
my @ks = sort keys %vals;

check_attrs(\@attrs, \@ks);

# Clean up for next round of testing
foreach (keys %vals)
{
    # delete it
    ok (delfattr($filename, $_));

    # check that it's gone
    is (getfattr($filename, $_), undef);
}

##########################
# IO::Handle-based tests #
##########################

$fh = new IO::File("<$filename") || die "Unable to open $filename";

print "# using file descriptor ".$fh->fileno()."\n";

foreach (keys %vals)
{
    # create it
    is (setfattr($fh, $_, $vals{$_}, { create => 1 }), 1);

    # create it again -- should fail
    is (setfattr($fh, $_, $vals{$_}, { create => 1 }), 0);

    # read it back
    is (getfattr($fh, $_), $vals{$_});
}

# Check that the list contains all the attributes.
@attrs = listfattr($fh);
@attrs = sort @attrs;
@ks = sort keys %vals;

check_attrs(\@attrs, \@ks);

# Clean up for next round of testing
foreach (keys %vals)
{
    # delete it
    ok (delfattr($filename, $_));

    # check that it's gone
    is (getfattr($filename, $_), undef);
}

END {unlink $filename if $filename};

sub check_attrs
{
    my @attrs = @{ $_[0] };
    my @ks = @{ $_[1] };

    is(scalar @attrs, scalar @ks);
    for (my $i = 0; $i < scalar @attrs; ++$i)
    {
        is($attrs[$i], $ks[$i]);
    }
}
