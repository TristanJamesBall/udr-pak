#include "any.h"
#include "../util/udr_util.h"

/* 
    string to "any_int" conversion
    If not specified with a ::type cast literal, picks the 
    smallest type possible as the "origin type"
    eg 1 == smallint, 525552 == integer etc etc

    Doing it this way means we can pretty print our 
    any_ints without type information,
    
    So  to_hex('-1'::any_int::lvarchar::any_int) prints 'ffff' and not 'ffffffff' or anything

    Look, it fixed an edge case in testing, I don't think it would ever matter.
*/
any_int_t *any_int_input(mi_lvarchar *text) {

    any_int_t *ret;
    char      *cp;
    char typename[32];

    ret = udr_alloc_ret(any_int_t);
    cp  = mi_lvarchar_to_string(text);

    if (sscanf(cp, "%ld::%s", &ret->val, typename) > 0) {

        if (strcasecmp(typename, "integer") == 0 || strcasecmp(typename, "serial") == 0) {

            ret->orig_type = CINTTYPE;

        } else if (strcasecmp(typename, "bigint") == 0 || strcasecmp(typename, "int8") == 0 || strcasecmp(typename, "bigserial") == 0 ||
                   strcasecmp(typename, "serial8") == 0) {

            ret->orig_type = CBIGINTTYPE;

        } else if (strcasecmp(typename, "smallint") == 0) {

            ret->orig_type = CSHORTTYPE;

        } else if (strcasecmp(typename, "boolean") == 0) {

            ret->orig_type = CBOOLTYPE;

        } else {
            if (ret->val < 0) {

                if (ret->val < INT32_MIN) {

                    ret->orig_type = CBIGINTTYPE;

                } else if (ret->val < INT16_MIN) {

                    ret->orig_type = CINTTYPE;

                } else {

                    ret->orig_type = CSHORTTYPE;
                }

            } else {
                if (ret->val > INT32_MAX) {

                    ret->orig_type = CBIGINTTYPE;

                } else if (ret->val > INT16_MAX) {

                    ret->orig_type = CINTTYPE;

                } else {

                    ret->orig_type = CSHORTTYPE;
                }
            }

        }
    }
    return (ret);
}

mi_lvarchar *any_int_output(any_int_t *in) {

    char         buf[MAXVCLEN];
    mi_lvarchar *ret;

    switch (in->orig_type) {
    case CBOOLTYPE: {
        snprintf(buf, MAXVCLEN, "%hd", (int)in->val);
        break;
    }
    case CSHORTTYPE: {
        snprintf(buf, MAXVCLEN, "%hd", (int)in->val);
        break;
    }
    case CINTTYPE: {
        snprintf(buf, MAXVCLEN, "%d", (int)in->val);
        break;
    }
    case CBIGINTTYPE: {
        snprintf(buf, MAXVCLEN, "%ld", in->val);
        break;
    }
    default: {
        mi_db_error_raise(NULL, MI_EXCEPTION, "Unknown origin type: %d", in->orig_type);
        return NULL;
        break;
    }
    }

    ret = mi_new_var(strlen(buf));

    mi_set_vardata(ret, buf);

    return (ret);
}

any_int_t *integer_to_any(mi_integer in, MI_FPARAM *fParam) {
    any_int_t *ret;

    if (!(ret = mi_dalloc(sizeof(any_int_t), PER_ROUTINE))) {
        return_enomem(NULL);
    };
    memset(ret, 0, sizeof(any_int_t));
    ret->val   = in;
    ret->orig_type = CINTTYPE;

    return ret;
}

any_int_t *bigint_to_any(mi_bigint *in, MI_FPARAM *fParam) {
    any_int_t *ret;

    if (!(ret = mi_dalloc(sizeof(any_int_t), PER_ROUTINE))) {
        return_enomem(NULL);
    };
    memset(ret, 0, sizeof(any_int_t));
    ret->val   = *in;
    ret->orig_type = CBIGINTTYPE;

    return ret;
}

any_int_t *smallint_to_any(mi_smallint in, MI_FPARAM *fParam) {
    any_int_t *ret;

    if (!(ret = mi_dalloc(sizeof(any_int_t), PER_ROUTINE))) {
        return_enomem(NULL);
    };
    memset(ret, 0, sizeof(any_int_t));
    ret->val   = in;
    ret->orig_type = CSHORTTYPE;

    return ret;
}

any_int_t *boolean_to_any(mi_boolean in, MI_FPARAM *fParam) {
    any_int_t *ret;

    if (!(ret = mi_dalloc(sizeof(any_int_t), PER_ROUTINE))) {
        return_enomem(NULL);
    };
    memset(ret, 0, sizeof(any_int_t));
    ret->val    = in;
    ret->orig_type = CBOOLTYPE;

    return ret;
}

mi_integer any_to_integer(any_int_t *in, MI_FPARAM *fParam) {

    switch (in->orig_type) {
    case CBOOLTYPE: {
        return (mi_integer)in->val;
        break;
    }
    case CSHORTTYPE: {
        return (mi_integer)in->val;
        break;
    }

    case CINTTYPE: {
        return (mi_integer)in->val;
        break;
    }
    case CBIGINTTYPE: {
        if (in->val < INT32_MAX && in->val > INT32_MIN) {
            return (mi_integer)in->val;
        }
        mi_db_error_raise(NULL, MI_EXCEPTION, "Overflow, to big for target type");
        return 0;
        break;
    }
    default: {
        mi_db_error_raise(NULL, MI_EXCEPTION, "Unknown origin type: %d", in->orig_type);
        return 0;
        break;
    }
    }
}

mi_smallint any_to_smallint(any_int_t *in, MI_FPARAM *fParam) {

    switch (in->orig_type) {
    case CBOOLTYPE: {
        return (mi_smallint)in->val;
        break;
    }
    case CSHORTTYPE: {
        return (mi_smallint)in->val;
        break;
    }
    case CINTTYPE:
    case CBIGINTTYPE: {
        if (in->val < INT16_MAX && in->val > INT16_MIN) {
            return (mi_smallint)in->val;
        }
        mi_db_error_raise(NULL, MI_EXCEPTION, "Overflow, to big for target type");
        return 0;
        break;
    }
    default: {
        mi_db_error_raise(NULL, MI_EXCEPTION, "Unknown origin type: %d", in->orig_type);
        return 0;
        break;
    }
    }
}

mi_bigint *any_to_bigint(any_int_t *in, MI_FPARAM *fParam) {
    mi_bigint *ret;

    switch (in->orig_type) {
    case CBOOLTYPE:
    case CSHORTTYPE:
    case CINTTYPE:
    case CBIGINTTYPE: {
        if (!(ret = udr_alloc_ret(mi_bigint))) {
            return_enomem(NULL);
        };
        *ret = in->val;
        return ret;
        break;
    }
    default: {
        mi_db_error_raise(NULL, MI_EXCEPTION, "Unknown origin type: %d", in->orig_type);
        return NULL;
        break;
    }
    }
}

mi_boolean any_to_boolean(any_int_t *in, MI_FPARAM *fParam) {

    if (in->val == 0) {
        return MI_FALSE;
    }
    return MI_TRUE;
}
