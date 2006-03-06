#ifndef EXTATTR_PORTABLE_H
#define EXTATTR_PORTABLE_H

#include <sys/types.h>
#ifdef __APPLE__
#include <sys/xattr.h>
#elif defined(BSD) /* FreeBSD, NetBSD, OpenBSD */
#include <sys/extattr.h>
#include <sys/uio.h>
#else /* Linux */
#include <attr/attributes.h>
#include <attr/xattr.h>
#endif

#ifdef BSD

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

#endif /* BSD */

static inline int
portable_setxattr (const char *path,
                   const char *attrname,
                   const void *attrvalue,
                   const size_t slen,
                   const int flags)
{
#ifdef __APPLE__
  return setxattr(path, attrname, attrvalue, slen, 0, flags);
#elif defined(BSD)
  /* XXX: Namespace? */
  int ret = extattr_set_file(path, EXTATTR_NAMESPACE_USER, attrname, attrvalue, slen);
  return bsd_extattr_set_succeeded(slen, ret);
#else
  return setxattr(path, attrname, attrvalue, slen, flags);
#endif
}

static inline int
portable_fsetxattr (const int fd,
                    const char *attrname,
                    const void *attrvalue,
                    const size_t slen,
                    const int flags)
{
#ifdef __APPLE__
  return fsetxattr(fd, attrname, attrvalue, slen, 0, flags);
#elif defined(BSD)
  /* XXX: Namespace? */
  int ret = extattr_set_fd(fd, EXTATTR_NAMESPACE_USER, attrname, attrvalue, slen);
  return bsd_extattr_set_succeeded(slen, ret);
#else
  return fsetxattr(fd, attrname, attrvalue, slen, flags);
#endif
}

static inline int
portable_getxattr (const char *path,
                   const char *attrname,
                   void *attrvalue,
                   const size_t slen)
{
#ifdef __APPLE__
  return getxattr(path, attrname, attrvalue, slen, 0, 0);
#elif defined(BSD)
  /* XXX: Namespace? */
  return extattr_get_file(path, EXTATTR_NAMESPACE_USER, attrname, attrvalue, slen);
#else
  return getxattr(path, attrname, attrvalue, slen);
#endif
}

static inline int
portable_fgetxattr (const int fd,
                    const char *attrname,
                    void *attrvalue,
                    const size_t slen)
{
#ifdef __APPLE__
  return fgetxattr(fd, attrname, attrvalue, slen, 0, 0);
#elif defined(BSD)
  /* XXX: Namespace? */
  return extattr_get_fd(fd, EXTATTR_NAMESPACE_USER, attrname, attrvalue, slen);
#else
  return fgetxattr(fd, attrname, attrvalue, slen);
#endif
}

static inline ssize_t
portable_lenxattr (const char *path, const char *attrname)
{
#ifdef BSD
  /* XXX: Namespace? */
  return extattr_get_file(path, EXTATTR_NAMESPACE_USER, attrname, NULL, 0);
#else
  return portable_getxattr(path, attrname, NULL, 0);
#endif
}

static inline int
portable_flenxattr (int fd, const char *attrname)
{
#ifdef BSD
  /* XXX: Namespace? */
  return extattr_get_fd(fd, EXTATTR_NAMESPACE_USER, attrname, NULL, 0);
#else
  return portable_fgetxattr(fd, attrname, NULL, 0);
#endif
}

static inline int
portable_removexattr (const char *path, const char *name)
{
#ifdef __APPLE__
  return removexattr(path, name, 0);
#elif defined(BSD)
  /* XXX: Namespace? */
  return extattr_delete_file(path, EXTATTR_NAMESPACE_USER, name);
#else
  return removexattr(path, name);
#endif
}

static inline int
portable_fremovexattr (const int fd, const char *name)
{
#ifdef __APPLE__
  return fremovexattr(fd, name, 0);
#elif defined(BSD)
  /* XXX: Namespace? */
  return extattr_delete_fd(fd, EXTATTR_NAMESPACE_USER, name);
#else
  return fremovexattr(fd, name);
#endif
}

#endif /* EXTATTR_PORTABLE_H */
