#include "extattr_os.h"

#ifdef EXTATTR_SOLARIS

#include <errno.h>
#include <unistd.h>

static const mode_t ATTRMODE = S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP;

static inline int
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

static inline int
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

static inline int
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

int
solaris_setxattr (const char *path,
		  const char *attrname,
		  const char *attrvalue,
		  const size_t slen,
		  const int flags)
{
  /* XXX: Support overwrite/no overwrite flags */
  int saved_errno = 0;
  int ok = 1;
  int attrfd = attropen(path, attrname, O_RDWR|O_CREAT, ATTRMODE);

  /* XXX: More common code? */
  if (attrfd == -1)
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
		       const int flags)
{
  /* XXX: Support overwrite/no overwrite flags */
  int saved_errno = 0;
  int ok = 1;
  int attrfd = openat(fd, attrname, O_RDWR|O_CREAT|O_XATTR, ATTRMODE);

  /* XXX: More common code? */
  if (attrfd == -1)
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
		  const size_t slen)
{
  const int attrfd = attropen(path, attrname, O_RDONLY);
  return readclose(attrfd, attrvalue, slen);
}

int
solaris_fgetxattr (const int fd,
		   const char *attrname,
		   void *attrvalue,
		   const size_t slen)
{
  int attrfd = openat(fd, attrname, O_RDONLY|O_XATTR);
  return readclose(attrfd, attrvalue, slen);
}

int
solaris_removexattr (const char *path, const char *attrname)
{
  int attrdirfd = attropen(path, ".", O_RDONLY);
  return unlinkclose(attrdirfd, attrname);
}

int
solaris_fremovexattr (const int fd, const char *attrname)
{
  int attrdirfd = openat(fd, ".", O_RDONLY|O_XATTR);
  return unlinkclose(attrdirfd, attrname);
}

#endif /* EXTATTR_SOLARIS */
