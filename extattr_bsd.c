#ifdef EXTATTR_BSD

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

#endif /* EXTATTR_BSD */
