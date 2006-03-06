#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "helpers.h"
#include "portable.h"

/* NB: Include this after portable.h (or <sys/xattr.h>) */
#include "const-c.inc"

#define MAX_INITIAL_VALUELEN_VARNAME "File::ExtAttr::MAX_INITIAL_VALUELEN"
                                        /* Richard, fixme! */


MODULE = File::ExtAttr        PACKAGE = File::ExtAttr		

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE


int 
_setfattr (path, attrname, attrvalueSV, flags = 0)
         const char *path
         const char *attrname
         SV * attrvalueSV
         int flags
    CODE:
        STRLEN slen;
        char * attrvalue;
        int rc;

        attrvalue = SvPV(attrvalueSV, slen);
        rc = portable_setxattr(path, attrname, attrvalue, slen, flags);
        if (rc == -1)
        {
                setattr_warn("setxattr", attrname, errno);
                XSRETURN_UNDEF;
        }
        RETVAL = (rc == 0);
    OUTPUT: 
        RETVAL


int 
_fsetfattr (fd, attrname, attrvalueSV, flags = 0)
         int fd
         const char *attrname
         SV * attrvalueSV
         int flags
    CODE:
        STRLEN slen;
        char * attrvalue;
        int rc;

        attrvalue = SvPV(attrvalueSV, slen);
        rc = portable_fsetxattr(fd, attrname, attrvalue, slen, flags);
        if (rc == -1)
        {
                setattr_warn("fsetxattr", attrname, errno);
                XSRETURN_UNDEF;
        }
        RETVAL = (rc == 0);
    OUTPUT: 
        RETVAL


SV *
_getfattr(path, attrname, flags = 0)
        const char *path
        const char *attrname
        int flags
   CODE:
        char * attrvalue;
        int attrlen;
        ssize_t buflen;

        buflen = portable_lenxattr(path, attrname);
        if (buflen <= 0)
	  buflen = SvIV(get_sv(MAX_INITIAL_VALUELEN_VARNAME, FALSE));

        attrvalue = NULL;
        New(1, attrvalue, buflen, char);

        attrlen = portable_getxattr(path, attrname, attrvalue, buflen);
        if (attrlen == -1){

            //key not found, just return undef
            if(errno == ENOATTR){
                XSRETURN_UNDEF;

            //print warning and return undef
            }else{
            char * errstr;
                New(1, errstr, 1000, char);
                warn("getxattr failed: %s",strerror_r(errno,errstr,1000)); 
                Safefree(errstr);
                XSRETURN_UNDEF;
            }
        }
        RETVAL = newSVpv(attrvalue, attrlen);
        Safefree(attrvalue);
    OUTPUT:
        RETVAL


SV *
_fgetfattr(fd, attrname, flags = 0)
        int fd
        const char *attrname
        int flags
   CODE:
        char * attrvalue;
        int attrlen;
        ssize_t buflen;

        buflen = portable_flenxattr(fd, attrname);
        if (buflen <= 0)
	  buflen = SvIV(get_sv(MAX_INITIAL_VALUELEN_VARNAME, FALSE));

        attrvalue = NULL;
        New(1, attrvalue, buflen, char);

        attrlen = portable_fgetxattr(fd, attrname, attrvalue, buflen);
        if (attrlen == -1){

            //key not found, just return undef
            if(errno == ENOATTR){
                XSRETURN_UNDEF;

            //print warning and return undef
            }else{
            char * errstr;
                New(1, errstr, 1000, char);
                warn("fgetxattr failed: %s",strerror_r(errno,errstr,1000)); 
                Safefree(errstr);
                XSRETURN_UNDEF;
            }
        }
        RETVAL = newSVpv(attrvalue, attrlen);
        Safefree(attrvalue);
    OUTPUT:
        RETVAL


int 
_delfattr (path, attrname, flags = 0)
        const char *path
        const char *attrname
        int flags
    CODE:
        RETVAL = (portable_removexattr(path, attrname) == 0);
    
    OUTPUT: 
        RETVAL


int 
_fdelfattr (fd, attrname, flags = 0)
        int fd
        const char *attrname
        int flags
    CODE:
        RETVAL = (portable_fremovexattr(fd, attrname) == 0);
    
    OUTPUT: 
        RETVAL

void
_listfattr (path, fd)
         const char *path
         int fd
    INIT:
        ssize_t size, ret;
        char *namebuf = NULL;
        char *nameptr;
    PPCODE:
        if(fd == -1)
            size = portable_listxattr(path, NULL, 0);
        else
            size = portable_flistxattr(fd, NULL, 0);

        if (size == -1)
        {
            XSRETURN_UNDEF;
        } else if (size == 0)
        {
            XSRETURN_EMPTY;
        }

        namebuf = malloc(size);

        if (fd == -1)
            ret = portable_listxattr(path, namebuf, size);
        else
            ret = portable_flistxattr(fd, namebuf, size);

        // There could be a race condition here, if someone adds a new
        // attribute between the two listxattr calls. However it just means we
        // might return ERANGE.

        if (ret == -1)
        {
            free(namebuf);
            XSRETURN_UNDEF;
        } else if (ret == 0)
        {
            free(namebuf);
            XSRETURN_EMPTY;
        }

        nameptr = namebuf;

        while(nameptr < namebuf + ret)
        {
          char *endptr = nameptr;
          while(*endptr++ != '\0');

          // endptr will now point one past the end..

          XPUSHs(sv_2mortal(newSVpvn(nameptr, endptr - nameptr - 1)));

          // nameptr could now point past the end of namebuf
          nameptr = endptr;
        }

        free(namebuf);
