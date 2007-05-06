package t::Support;

use strict;
use Config;

sub should_skip {
  # NetBSD 3.1 and earlier don't support xattrs.
  # See <http://www.netbsd.org/Changes/changes-4.0.html#ufs>.
  if ($^O eq 'netbsd') {
    my @t = split(/\./, $Config{osvers});
    return 1 if ($t[0] <= 3);
  }

  return 0;
}

1;

