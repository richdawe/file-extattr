#ifndef EXTATTR_PORTABLE_H
#define EXTATTR_PORTABLE_H

#ifdef __MACOSX__
#include <sys/xattr.h>
#else /* Linux */
#include <attr/attributes.h>
#include <attr/xattr.h>
#endif
#include <sys/types.h>

static inline int
portable_setxattr (const char *path,
                   const char *attrname,
                   const void *attrvalue,
                   const size_t slen,
                   const int flags)
{
#ifdef __MACOSX__
  return setxattr(path, attrname, attrvalue, slen, 0, flags);
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
#ifdef __MACOSX__
  return fsetxattr(fd, attrname, attrvalue, slen, 0, flags);
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
#ifdef __MACOSX__
  return getxattr(path, attrname, attrvalue, slen, 0, 0);
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
#ifdef __MACOSX__
  return fgetxattr(fd, attrname, attrvalue, slen, 0, 0);
#else
  return fgetxattr(fd, attrname, attrvalue, slen);
#endif
}

static inline int
portable_removexattr (const char *path, const char *name)
{
#ifdef __MACOSX__
  return removexattr(path, name, 0);
#else
  return removexattr(path, name);
#endif
}

static inline int
portable_fremovexattr (const int fd, const char *name)
{
#ifdef __MACOSX__
  return fremovexattr(fd, name, 0);
#else
  return fremovexattr(fd, name);
#endif
}

#endif /* EXTATTR_PORTABLE_H */
