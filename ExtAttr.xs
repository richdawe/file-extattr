#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <attr/attributes.h>
#include <attr/xattr.h>
#include <sys/types.h>

#include "const-c.inc"
#include "helpers.h"

#define MAX_INITIAL_VALUELEN_VARNAME "File::ExtAttr::MAX_INITIAL_VALUELEN"
                                        /* Richard, fixme! */


MODULE = File::ExtAttr        PACKAGE = File::ExtAttr		

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE


int 
setfattr (path, attrname, attrvalueSV, flags = 0)
         const char *path
         const char *attrname
         SV * attrvalueSV
         int flags
    CODE:
        STRLEN slen;
        char * attrvalue;
        int rc;

        attrvalue = SvPV(attrvalueSV, slen);
        rc = setxattr(path,attrname,attrvalue,slen,flags);
        if (rc == -1)
        {
                setattr_warn("setxattr", attrname, errno);
                XSRETURN_UNDEF;
        }
        RETVAL = (rc == 0);
    OUTPUT: 
        RETVAL


SV *
getfattr(path, attrname)
        const char *path
         const char *attrname
   CODE:
        char * attrvalue;
        int attrlen;
        STRLEN buflen = SvIV(get_sv(MAX_INITIAL_VALUELEN_VARNAME, FALSE));

        attrvalue = NULL;

        //try first at our default value $File::ExtAttr::MAX_INITIAL_VALUELEN
        New(1, attrvalue, buflen, char);
        attrlen = getxattr(path, attrname, attrvalue, buflen);
        if (attrlen == -1){
            if (errno == ERANGE) {
                //ok, look up the real length
                attrlen = getxattr(path, attrname, attrvalue, 0);
                Safefree(attrvalue);
                New(1, attrvalue, attrlen, char);
                attrlen = getxattr(path, attrname, attrvalue, attrlen);
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



int 
delfattr (path, attrname)
         const char *path
         const char *attrname
    CODE:
        RETVAL = (removexattr(path,attrname) == 0);
    
    OUTPUT: 
        RETVAL



