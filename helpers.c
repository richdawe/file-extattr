#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>

#include "helpers.h"

void
setattr_warn (const char *funcname, const char *attrname, const int the_errno)
{
  int is_user_xattr;
  char * errstr;

  is_user_xattr = (strncmp(attrname, "user.", 5) == 0); 
  New(1, errstr, 1000, char);

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
               strerror_r(the_errno,errstr,1000));
        }
      else
        {
          warn("%s failed: %s"
               " - perhaps the filesystem needs to be mounted"
               " with an option to enable extended attributes?",
               funcname,
               strerror_r(the_errno,errstr,1000));
        }
    }
  else
    {
      warn("%s failed: %s",
           funcname,
           strerror_r(the_errno,errstr,1000)); 
    }

  Safefree(errstr);
}
