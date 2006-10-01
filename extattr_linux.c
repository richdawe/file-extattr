#include "extattr_os.h"

#ifdef EXTATTR_LINUX

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "flags.h"

static void *
memstr (void *buf, const char *str, const size_t buflen)
{
  void *p = buf;
  size_t len = buflen;
  const size_t slen = strlen(str);

  /* Ignore empty strings and buffers. */
  if ((slen == 0) || (buflen == 0))
    p = NULL;

  while (p && (len >= slen))
  {
    /*
     * Find the first character of the string, then see if the rest
     * matches.
     */
    p = memchr(p, str[0], len);
    if (!p)
      break;

    if (memcmp(p, str, slen) == 0)
      break;

    /* Next! */
    ++p;
    --len;
  }

  return p;
}

static char *
flags2namespace (struct hv *flags)
{
  static const char NAMESPACE_DEFAULT[] = "user";
  const size_t NAMESPACE_KEYLEN = strlen(NAMESPACE_KEY);
  SV **psv_ns;
  char *ns = NULL;

  if (flags && (psv_ns = hv_fetch(flags, NAMESPACE_KEY, NAMESPACE_KEYLEN, 0)))
  {
    char *s;
    STRLEN len;

    s = SvPV(*psv_ns, len);
    ns = malloc(len + 1);
    if (ns)
    {
      strncpy(ns, s, len);
      ns[len] = '\0';
    }
  }
  else
  {
    ns = strdup(NAMESPACE_DEFAULT);
  }

  return ns;
}

static char *
qualify_attrname (const char *attrname, struct hv *flags)
{
  char *res = NULL;
  char *ns;
  size_t reslen;

  ns = flags2namespace(flags);
  if (ns)
  {
    reslen = strlen(ns) + strlen(attrname) + 2; /* ns + "." + attrname + nul */
    res = malloc(reslen);
  }

  if (res)
    snprintf(res, reslen, "%s.%s", ns, attrname);

  if (ns)
    free(ns);

  return res;
}

int
linux_setxattr (const char *path,
                const char *attrname,
                const char *attrvalue,
                const size_t slen,
                struct hv *flags)
{
  int ret;
  char *q;
  File_ExtAttr_setflags_t setflags;
  int xflags = 0;

  setflags = File_ExtAttr_flags2setflags(flags);
  switch (setflags)
  {
  case SET_CREATEIFNEEDED: break;
  case SET_CREATE:         xflags |= XATTR_CREATE; break;
  case SET_REPLACE:        xflags |= XATTR_REPLACE; break;
  }

  q = qualify_attrname(attrname, flags);
  if (q)
  {
    ret = setxattr(path, q, attrvalue, slen, xflags);
    free(q);
  }
  else
  {
    ret = -1;
    errno = ENOMEM;
  }

  return ret;
}

int
linux_fsetxattr (const int fd,
                 const char *attrname,
                 const char *attrvalue,
                 const size_t slen,
                 struct hv *flags)
{
  int ret;
  char *q;
  File_ExtAttr_setflags_t setflags;
  int xflags = 0;

  setflags = File_ExtAttr_flags2setflags(flags);
  switch (setflags)
  {
  case SET_CREATEIFNEEDED: break;
  case SET_CREATE:         xflags |= XATTR_CREATE; break;
  case SET_REPLACE:        xflags |= XATTR_REPLACE; break;
  }

  q = qualify_attrname(attrname, flags);
  if (q)
  {
    ret = fsetxattr(fd, q, attrvalue, slen, xflags);
    free(q);
  }
  else
  {
    ret = -1;
    errno = ENOMEM;
  }

  return ret;
}

int
linux_getxattr (const char *path,
                const char *attrname,
                void *attrvalue,
                const size_t slen,
                struct hv *flags)
{
  int ret;
  char *q;

  q = qualify_attrname(attrname, flags);
  if (q)
  {
    ret = getxattr(path, q, attrvalue, slen);
    free(q);
  }
  else
  {
    ret = -1;
    errno = ENOMEM;
  }

  return ret;
}

int
linux_fgetxattr (const int fd,
                 const char *attrname,
                 void *attrvalue,
                 const size_t slen,
                 struct hv *flags)
{
  int ret;
  char *q;

  q = qualify_attrname(attrname, flags);
  if (q)
  {
    ret = fgetxattr(fd, q, attrvalue, slen);
    free(q);
  }
  else
  {
    ret = -1;
    errno = ENOMEM;
  }

  return ret;
}

int
linux_removexattr (const char *path,
                   const char *attrname,
                   struct hv *flags)
{
  int ret;
  char *q;

  /* XXX: Other flags? */
  q = qualify_attrname(attrname, flags);
  if (q)
  {
    ret = removexattr(path, q);
    free(q);
  }
  else
  {
    ret = -1;
    errno = ENOMEM;
  }

  return ret;
}

int
linux_fremovexattr (const int fd,
                    const char *attrname,
                    struct hv *flags)
{
  int ret;
  char *q;

  /* XXX: Other flags? */
  q = qualify_attrname(attrname, flags);
  if (q)
  {
    ret = fremovexattr(fd, q);
    free(q);
  }
  else
  {
    ret = -1;
    errno = ENOMEM;
  }

  return ret;
}

ssize_t
linux_listxattr (const char *path,
                 char *buf,
                 const size_t buflen,
                 struct hv *flags)
{
#if 0
  /* XXX: We need some kind of hash returned here: { namespace => attrname } */
  int ret;
  char *q;

  /* XXX: Other flags? */
  q = qualify_attrname(attrname, flags);
  if (q)
  {
    ret = listxattr(path, buf, buflen);
    free(q);
  }
  else
  {
    ret = -1;
    errno = ENOMEM;
  }

  return ret;
#else
  return listxattr(path, buf, buflen);
#endif
}

ssize_t
linux_flistxattr (const int fd,
                  char *buf,
                  const size_t buflen,
                  struct hv *flags)
{
  return flistxattr(fd, buf, buflen);
}

static ssize_t
attrlist2nslist (char *sbuf, const size_t slen, char *buf, const size_t buflen)
{
  ssize_t sbuiltlen = 0;
  ssize_t spos = 0;
  int ret = -1;

  for (spos = 0; (spos < slen); )
  {
    char *pns, *pval;

    /* Get the namespace. */
    pns = &sbuf[spos];
    pval = strchr(pns, '.');
    if (!pval)
      break;

    /* Point spos at the next attribute. */
    spos += strlen(pval) + 1;

    /* Check we haven't already seen this namespace. */
    *pval = '\0';
    ++pval;
    if (memstr(sbuf, pns, sbuiltlen) != NULL)
      continue;

    /*
     * We build the results in sbuf. So sbuf will contain the list
     * returned by listxattr and the list of namespaces.
     * We shift the namespaces from the list to the start of the buffer.
     */
    memmove(&sbuf[sbuiltlen], pns, strlen(pns) + 1 /* nul */);
    sbuiltlen += strlen(pns) + 1;
  }

  if (buflen == 0)
  {
    /* Return what space is required. */
    ret = sbuiltlen;
  }
  else if (sbuiltlen <= buflen)
  {
    memcpy(buf, sbuf, sbuiltlen);
    ret = sbuiltlen;
  }
  else
  {
    errno = ERANGE;
    ret = -1;
  }

  return ret;
}

/* XXX: Just return a Perl list? */
ssize_t
linux_listxattrns (const char *path,
		   char *buf,
		   const size_t buflen,
		   struct hv *flags)
{
  ssize_t slen;
  ssize_t ret;

  /*
   * Get a buffer of nul-delimited "namespace.attribute"s,
   * then extract the namespaces into buf.
   */
  slen = listxattr(path, buf, 0);
  if (slen >= 0)
  {
    char *sbuf;
   
    sbuf = malloc(slen);
    if (sbuf)
      slen = listxattr(path, sbuf, slen);
    else
      ret = -1;

    if (slen)
      ret = attrlist2nslist(sbuf, slen, buf, buflen);
    else
      ret = slen;

    if (sbuf)
      free(sbuf);
  }
  else
  {
    ret = slen;
  }

  return ret;
}

ssize_t
linux_flistxattrns (const int fd,
		    char *buf,
		    const size_t buflen,
		    struct hv *flags)
{
  ssize_t slen;
  ssize_t ret;

  /*
   * Get a buffer of nul-delimited "namespace.attribute"s,
   * then extract the namespaces into buf.
   */
  slen = flistxattr(fd, buf, 0);
  if (slen >= 0)
  {
    char *sbuf;
   
    sbuf = malloc(slen);
    if (sbuf)
      slen = flistxattr(fd, sbuf, slen);
    else
      ret = -1;

    if (slen)
      ret = attrlist2nslist(sbuf, slen, buf, buflen);
    else
      ret = slen;

    if (sbuf)
      free(sbuf);
  }
  else
  {
    ret = slen;
  }

  return ret;
}

#endif /* EXTATTR_LINUX */
