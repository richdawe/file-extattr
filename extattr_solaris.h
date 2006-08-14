#ifndef EXTATTR_SOLARIS_H
#define EXTATTR_SOLARIS_H

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

/*
 * XXX: FIXME: Need to distinguish file non-existence and attribute
 * non-existence. Need to choose an unused error code somehow.
 */
#ifndef ENOATTR
#define ENOATTR ENOENT
#endif

int solaris_setxattr (const char *path,
		      const char *attrname,
		      const char *attrvalue,
		      const size_t slen,
		      const int flags);

int solaris_fsetxattr (const int fd,
		       const char *attrname,
		       const char *attrvalue,
		       const size_t slen,
		       const int flags);

int solaris_getxattr (const char *path,
		      const char *attrname,
		      void *attrvalue,
		      const size_t slen);

int solaris_fgetxattr (const int fd,
		       const char *attrname,
		       void *attrvalue,
		       const size_t slen);

int solaris_removexattr (const char *path, const char *attrname);

int solaris_fremovexattr (const int fd, const char *attrname);

ssize_t solaris_listxattr (const char *path,
			   char *buf,
			   const size_t buflen);

ssize_t solaris_flistxattr (const int fd,
			    char *buf,
			    const size_t buflen);

#endif /* EXTATTR_SOLARIS_H */
