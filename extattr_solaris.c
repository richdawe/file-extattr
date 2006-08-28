#include "extattr_os.h"

#ifdef EXTATTR_SOLARIS

#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "flags.h"

static const mode_t ATTRMODE = S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP;

typedef enum {
  SET_CREATEIFNEEDED = 0,
  SET_CREATE,
  SET_REPLACE
} setflags_t;

static setflags_t
flags2setflags (struct hv *flags)
{
  const size_t CREATE_KEYLEN = strlen(CREATE_KEY);
  const size_t REPLACE_KEYLEN = strlen(REPLACE_KEY);
  SV **psv_ns;
  setflags_t ret = SET_CREATEIFNEEDED;

  /*
   * ASSUMPTION: Perl layer must ensure that create & replace
   * aren't used at the same time.
   */
  if (flags && (psv_ns = hv_fetch(flags, CREATE_KEY, CREATE_KEYLEN, 0)))
    ret = SvIV(*psv_ns) ? SET_CREATE : SET_CREATEIFNEEDED;

  if (flags && (psv_ns = hv_fetch(flags, REPLACE_KEY, REPLACE_KEYLEN, 0)))
    ret = SvIV(*psv_ns) ? SET_REPLACE : SET_CREATEIFNEEDED;

  return ret;
}

static int
valid_namespace (struct hv *flags)
{
  const size_t NAMESPACE_KEYLEN = strlen(NAMESPACE_KEY);
  SV **psv_ns;
  char *ns = NULL;
  int ok = 1; /* Default is valid */

  if (flags && (psv_ns = hv_fetch(flags, NAMESPACE_KEY, NAMESPACE_KEYLEN, 0)))
  {
    /*
     * Undefined => default. Otherwise treat "user" as if it were valid,
     * for compatibility with the default on Linux and *BSD.
     * An empty namespace (i.e.: zero-length) is not the same as the default.
     */
    if (SvOK(*psv_ns))
    {
      char *s;
      STRLEN len = 0;

      s = SvPV(*psv_ns, len);

      if (len)
	ok = (memcmp("user", s, len) == 0);
      else
	ok = 0;
    }
  }

  return ok;
}

static int
writexattr (const int attrfd,
	    const char *attrvalue,
	    const size_t slen)
{
  int ok = 1;

  if (ftruncate(attrfd, 0) == -1)
    ok = 0;
  if (ok && (write(attrfd, attrvalue, slen) != slen))
    ok = 0;

  return ok ? 0 : -1;
}

static int
readclose (const int attrfd,
	   void *attrvalue,
	   const size_t slen)
{
  int sz = 0;
  int saved_errno = 0;
  int ok = 1;

  if (attrfd == -1)
    ok = 0;

  if (ok)
  {
    if (slen)
    {
      sz = read(attrfd, attrvalue, slen);
    }
    else
    {
      /* Request to see how much data is there. */
      struct stat sbuf;

      if (fstat(attrfd, &sbuf) == 0)
	sz = sbuf.st_size;
      else
	sz = -1;
    }

    if (sz == -1)
      ok = 0;
  }

  if (!ok)
    saved_errno = errno;
  if ((attrfd >= 0) && (close(attrfd) == -1) && !saved_errno)
    saved_errno = errno;
  if (saved_errno)
    errno = saved_errno;

  return ok ? sz : -1;
}

static int
unlinkclose (const int attrdirfd, const char *attrname)
{
  int sz = 0;
  int saved_errno = 0;
  int ok = 1;

  if (attrdirfd == -1)
    ok = 0;

  if (ok && (unlinkat(attrdirfd, attrname, 0) == -1))
    ok = 0;

  if (!ok)
    saved_errno = errno;
  if ((attrdirfd >= 0) && (close(attrdirfd) == -1) && !saved_errno)
    saved_errno = errno;
  if (saved_errno)
    errno = saved_errno;

  return ok ? sz : -1;  
}

static ssize_t
listclose (const int attrdirfd, char *buf, const size_t buflen)
{
  int saved_errno = 0;
  int ok = 1;
  ssize_t len = 0;
  DIR *dirp;

  if (attrdirfd == -1)
    ok = 0;

  if (ok)
    dirp = fdopendir(attrdirfd);

  if (ok)
  {
    struct dirent *de;

    while ((de = readdir(dirp)))
    {
      const size_t namelen = strlen(de->d_name);

      /* Ignore "." and ".." entries */
      if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, ".."))
	continue;

      if (buflen)
      {
	/* Check for space, then copy directory name + nul into list. */
	if ((len + namelen + 1) > buflen)
	{
	  errno = ERANGE;
	  ok = 0;
	  break;
	}
	else
	{
	  strcpy(buf + len, de->d_name);
	  len += namelen;
	  buf[len] = '\0';
	  ++len;
	}
      }
      else
      {
	/* Seeing how much space is needed? */
	len += namelen + 1;
      }
    }
  }

  if (!ok)
    saved_errno = errno;
  if ((attrdirfd >= 0) && (close(attrdirfd) == -1) && !saved_errno)
    saved_errno = errno;
  if (saved_errno)
    errno = saved_errno;

  return ok ? len : -1;
}

int
solaris_setxattr (const char *path,
		  const char *attrname,
		  const char *attrvalue,
		  const size_t slen,
		  struct hv *flags)
{
  /* XXX: Support overwrite/no overwrite flags */
  int saved_errno = 0;
  int ok = 1;
  setflags_t setflags;
  int openflags = O_RDWR;
  int attrfd = -1;

  setflags = flags2setflags(flags);
  switch (setflags)
  {
  case SET_CREATEIFNEEDED: openflags |= O_CREAT; break;
  case SET_CREATE:         openflags |= O_CREAT | O_EXCL; break;
  case SET_REPLACE:        break;
  }

  if (!valid_namespace(flags))
  {
    errno = ENOATTR;
    ok = 0;
  }

  if (ok)
    attrfd = attropen(path, attrname, openflags, ATTRMODE);

  /* XXX: More common code? */
  if (ok && (attrfd == -1))
    ok = 0;
  if (ok && (writexattr(attrfd, attrvalue, slen) == -1))
    ok = 0;

  if (!ok)
    saved_errno = errno;
  if ((attrfd >= 0) && (close(attrfd) == -1) && !saved_errno)
    saved_errno = errno;
  if (saved_errno)
    errno = saved_errno;

  return ok ? 0 : -1;
}

int solaris_fsetxattr (const int fd,
		       const char *attrname,
		       const char *attrvalue,
		       const size_t slen,
		       struct hv *flags)
{
  /* XXX: Support overwrite/no overwrite flags */
  int saved_errno = 0;
  int ok = 1;
  int openflags = O_RDWR | O_XATTR;
  setflags_t setflags;
  int attrfd = -1;

  setflags = flags2setflags(flags);
  switch (setflags)
  {
  case SET_CREATEIFNEEDED: openflags |= O_CREAT; break;
  case SET_CREATE:         openflags |= O_CREAT | O_EXCL; break;
  case SET_REPLACE:        break;
  }

  if (!valid_namespace(flags))
  {
    errno = ENOATTR;
    ok = 0;
  }

  if (ok)
    attrfd = openat(fd, attrname, openflags, ATTRMODE);

  /* XXX: More common code? */
  if (ok && (attrfd == -1))
    ok = 0;
  if (ok && (writexattr(attrfd, attrvalue, slen) == -1))
    ok = 0;

  if (!ok)
    saved_errno = errno;
  if ((attrfd >= 0) && (close(attrfd) == -1) && !saved_errno)
    saved_errno = errno;
  if (saved_errno)
    errno = saved_errno;

  return ok ? 0 : -1;
}

int
solaris_getxattr (const char *path,
		  const char *attrname,
		  void *attrvalue,
		  const size_t slen,
		  struct hv *flags)
{
  int attrfd = -1;
  int ok = 1;

  if (!valid_namespace(flags))
  {
    errno = ENOATTR;
    ok = 0;
  }

  if (ok)
    attrfd = attropen(path, attrname, O_RDONLY);

  return ok ? readclose(attrfd, attrvalue, slen) : -1;
}

int
solaris_fgetxattr (const int fd,
		   const char *attrname,
		   void *attrvalue,
		   const size_t slen,
		   struct hv *flags)
{
  int attrfd = -1;
  int ok = 1;

  if (!valid_namespace(flags))
  {
    errno = ENOATTR;
    ok = 0;
  }

  if (ok)
    attrfd = openat(fd, attrname, O_RDONLY|O_XATTR);

  return ok ? readclose(attrfd, attrvalue, slen) : -1;
}

int
solaris_removexattr (const char *path,
		     const char *attrname,
		     struct hv *flags)
{
  int attrdirfd = -1;
  int ok = 1;

  if (!valid_namespace(flags))
  {
    errno = ENOATTR;
    ok = 0;
  }

  if (ok)
    attrdirfd = attropen(path, ".", O_RDONLY);

  return ok ? unlinkclose(attrdirfd, attrname) : -1;
}

int
solaris_fremovexattr (const int fd,
		      const char *attrname,
		      struct hv *flags)
{
  int attrdirfd = -1;
  int ok = 1;

  if (!valid_namespace(flags))
  {
    errno = ENOATTR;
    ok = 0;
  }

  if (ok)
    attrdirfd = openat(fd, ".", O_RDONLY|O_XATTR);

  return ok ? unlinkclose(attrdirfd, attrname) : -1;
}

ssize_t
solaris_listxattr (const char *path,
		   char *buf,
		   const size_t buflen,
		   struct hv *flags)
{
  int attrdirfd = attropen(path, ".", O_RDONLY);
  return listclose(attrdirfd, buf, buflen);
}

ssize_t
solaris_flistxattr (const int fd,
		    char *buf,
		    const size_t buflen,
		    struct hv *flags)
{
  int attrdirfd = openat(fd, ".", O_RDONLY|O_XATTR);
  return listclose(attrdirfd, buf, buflen);
}

#endif /* EXTATTR_SOLARIS */
