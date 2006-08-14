#ifndef EXTATTR_BSD_H
#define EXTATTR_BSD_H

#include <sys/types.h>
#include <sys/extattr.h>
#include <sys/uio.h>

int bsd_setxattr (const char *path,
		  const char *attrname,
		  const char *attrvalue,
		  const size_t slen);

int bsd_fsetxattr (const int fd,
		   const char *attrname,
		   const char *attrvalue,
		   const size_t slen);

#endif /* EXTATTR_BSD_H */
