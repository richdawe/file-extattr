package File::ExtAttr::Tie;
use strict;
use base qw(Tie::Hash);
use File::ExtAttr qw(:all);

sub TIEHASH {
  my($class, $file) = @_;
  return bless { file => $file }, ref $class || $class;
}

sub STORE {
  my($self, $name, $value) = @_;
  return undef unless setfattr($self->{file}, $name, $value);
  $value;
}

sub FETCH {
  my($self, $name) = @_;
  return getfattr($self->{file}, $name);
}

sub FIRSTKEY {
  my($self) = @_;
  $self->{each_list} = [listfattr($self->{file})];
  shift @{$self->{each_list}};
}

sub NEXTKEY {
  my($self) = @_;
  shift @{$self->{each_list}};
}

sub EXISTS {
  my($self, $name) = @_;
  return getfattr($self->{file}, $name) ne undef;
}

sub DELETE {
  my($self, $name) = @_;
  my $value = getfattr($self->{file}, $name);
  return $value if delfattr($self->{file}, $name);
  undef;
}

sub CLEAR {
  my($self) = @_;
  for(listfattr($self->{file})) {
    delfattr($self->{file}, $_);
  }
}

#sub SCALAR { }

1;
