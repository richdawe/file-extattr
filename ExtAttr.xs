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
_getfattr(path, attrname)
        const char *path
        const char *attrname
   CODE:
        char * attrvalue;
        int attrlen;
        STRLEN buflen = SvIV(get_sv(MAX_INITIAL_VALUELEN_VARNAME, FALSE));

        attrvalue = NULL;

        //try first at our default value $File::ExtAttr::MAX_INITIAL_VALUELEN
        New(1, attrvalue, buflen, char);
        attrlen = portable_getxattr(path, attrname, attrvalue, buflen);
        if (attrlen == -1){
            if (errno == ERANGE) {
                //ok, look up the real length
                attrlen = portable_getxattr(path, attrname, attrvalue, 0);
                Safefree(attrvalue);
                New(1, attrvalue, attrlen, char);
                attrlen = portable_getxattr(path, attrname, attrvalue, attrlen);
            }
        }


        //uh-oh, getxattr failed
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
_fgetfattr(fd, attrname)
        int fd
        const char *attrname
   CODE:
        char * attrvalue;
        int attrlen;
        STRLEN buflen = SvIV(get_sv(MAX_INITIAL_VALUELEN_VARNAME, FALSE));

        attrvalue = NULL;

        //try first at our default value $File::ExtAttr::MAX_INITIAL_VALUELEN
        New(1, attrvalue, buflen, char);
        attrlen = portable_fgetxattr(fd, attrname, attrvalue, buflen);
        if (attrlen == -1){
            if (errno == ERANGE) {
                //ok, look up the real length
                attrlen = portable_fgetxattr(fd, attrname, attrvalue, 0);
                Safefree(attrvalue);
                New(1, attrvalue, attrlen, char);
                attrlen = portable_fgetxattr(fd, attrname, attrvalue, attrlen);
            }
        }


        //uh-oh, getxattr failed
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
_delfattr (path, attrname)
         const char *path
         const char *attrname
    CODE:
        RETVAL = (portable_removexattr(path, attrname) == 0);
    
    OUTPUT: 
        RETVAL


int 
_fdelfattr (fd, attrname)
         int fd
         const char *attrname
    CODE:
        RETVAL = (portable_fremovexattr(fd, attrname) == 0);
    
    OUTPUT: 
        RETVAL
