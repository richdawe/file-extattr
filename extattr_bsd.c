#include "extattr_os.h"

#ifdef EXTATTR_BSD

#include <errno.h>

#include "extattr_bsd.h"

/* Helper to convert number of bytes written into success/failure code. */
static inline int
bsd_extattr_set_succeeded (const int expected, const int actual)
{
  int ret = -1;

  if (actual != -1)
  {
    if (actual != expected)
    {
      errno = ENOBUFS; /* Pretend there's not enough space for the data. */
      ret = -1;
    }
    else
    { 
      ret = 0;
    }
  }

  return ret;
}

int
bsd_setxattr (const char *path,
	      const char *attrname,
	      const char *attrvalue,
	      const size_t slen)
{
  /* XXX: Namespace? */
  int ret = extattr_set_file(path, EXTATTR_NAMESPACE_USER, attrname, attrvalue, slen);
  return bsd_extattr_set_succeeded(slen, ret);
}

int
bsd_fsetxattr (const int fd,
	       const char *attrname,
	       const char *attrvalue,
	       const size_t slen)
{
  /* XXX: Namespace? */
  int ret = extattr_set_fd(fd, EXTATTR_NAMESPACE_USER, attrname, attrvalue, slen);
  return bsd_extattr_set_succeeded(slen, ret);
}

/* Convert the BSD-style list to a nul-separated list. */
static void
reformat_list (char *buf, const ssize_t len)
{
  ssize_t pos = 0;
  ssize_t attrlen;

  while (pos < len)
  {
    attrlen = (unsigned char) buf[pos];
    memmove(buf + pos, buf + pos + 1, attrlen);
    buf[pos + attrlen] = '\0';
    pos += attrlen + 1;
  }
}

ssize_t
bsd_listxattr (const char *path, char *buf, const size_t buflen)
{
  ssize_t ret;

  /* XXX: Namespace? */
  ret = extattr_list_file(path,
			  EXTATTR_NAMESPACE_USER,
			  /* To get the length on *BSD, pass NULL here. */
			  buflen ? buf : NULL,
			  buflen);

  if (buflen && (ret > 0))
    reformat_list(buf, ret);

  return ret;
}

ssize_t
bsd_flistxattr (const int fd, char *buf, const size_t buflen)
{
  ssize_t ret;

  /* XXX: Namespace? */
  ret = extattr_list_fd(fd,
			EXTATTR_NAMESPACE_USER,
			/* To get the length on *BSD, pass NULL here. */
			buflen ? buf : NULL,
			buflen);

  if (buflen && (ret > 0))
    reformat_list(buf, ret);

  return ret;
}

#endif /* EXTATTR_BSD */
