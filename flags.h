#ifndef EXTATTR_FLAGS_H
#define EXTATTR_FLAGS_H

struct hv;

typedef enum {
  SET_CREATEIFNEEDED = 0,
  SET_CREATE,
  SET_REPLACE
} File_ExtAttr_setflags_t;

static const char NAMESPACE_KEY[] = "namespace";

static const char CREATE_KEY[] = "create";
static const char REPLACE_KEY[] = "replace";

File_ExtAttr_setflags_t File_ExtAttr_flags2setflags (struct hv *flags);
int File_ExtAttr_valid_default_namespace (struct hv *flags);

#endif /* EXTATTR_FLAGS_H */
