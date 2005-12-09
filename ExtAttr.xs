#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <attr/attributes.h>
#include <attr/xattr.h>
#include <sys/types.h>

#include "const-c.inc"

#define MAX_INITIAL_VALUELEN_VARNAME "File::ExtAttr::MAX_INITIAL_VALUELEN"
                                        /* Richard, fixme! */


MODULE = File::ExtAttr		PACKAGE = File::ExtAttr		

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE


int 
setfattr (path, attrname, attrvalueSV, flags)
         const char *path
         const char *attrname
         SV * attrvalueSV
         int flags
    CODE:
        STRLEN slen;
        char * attrvalue = SvPV(attrvalueSV, slen);
        RETVAL = (setxattr(path,attrname,attrvalue,slen,flags) == 0);
        //we need a hint in here, if they don't use "user." and they're
        //not root, the error message is just "Operation not supported"
        //which is really useless
    OUTPUT: 
        RETVAL


SV *
getfattr(path, attrname)
        const char *path
         const char *attrname
   CODE:
        char * attrvalue;
        char * errstr;
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
                New(1, attrvalue, attrlen-1, char);
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
                New(1, errstr, 1000, char);
                warn("attr_get failed: %s",strerror_r(errno,errstr,1000)); 
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



