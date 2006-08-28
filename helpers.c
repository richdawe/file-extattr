#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>

#include "helpers.h"

#ifdef __GLIBC__

static inline char *
my_strerror_r (const int the_errno, char *buf, const size_t buflen)
{
  buf[0] = '\0';

  return strerror_r(the_errno, buf, buflen);
}

#else

static inline char *
my_strerror_r (const int the_errno, char *buf, const size_t buflen)
{
  buf[0] = '\0';
  strerror_r(the_errno, buf, buflen);

  return buf;
}

#endif

void
setattr_warn (const char *funcname, const char *attrname, const int the_errno)
{
  static const size_t BUFLEN = 100;
  int is_user_xattr;
  char *buf;
  char *errstr;

  is_user_xattr = (strncmp(attrname, "user.", 5) == 0); 
  New(1, buf, BUFLEN, char);
  errstr = my_strerror_r(the_errno, buf, BUFLEN);

  // Try to give the user a useful hint of what went wrong.
  // Otherwise the error message is just "Operation not supported"
  // which is really unhelpful.
  if (the_errno == EOPNOTSUPP)
    {
      if (!is_user_xattr)
        {
          // XXX: Probably Linux-specific
          // XXX: What about other prefixes, e.g.: "security."?
          warn("%s failed: %s"
               " - perhaps the extended attribute's name"
               " needs a \"user.\" prefix?",
               funcname,
               errstr);
        }
      else
        {
          warn("%s failed: %s"
               " - perhaps the filesystem needs to be mounted"
               " with an option to enable extended attributes?",
               funcname,
               errstr);
        }
    }
  else
    {
      warn("%s failed: %s", funcname, errstr); 
    }

  Safefree(buf);
}
