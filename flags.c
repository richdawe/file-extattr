#include <stddef.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "flags.h"

File_ExtAttr_setflags_t
File_ExtAttr_flags2setflags (struct hv *flags)
{
  const size_t CREATE_KEYLEN = strlen(CREATE_KEY);
  const size_t REPLACE_KEYLEN = strlen(REPLACE_KEY);
  SV **psv_ns;
  File_ExtAttr_setflags_t ret = SET_CREATEIFNEEDED;

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
