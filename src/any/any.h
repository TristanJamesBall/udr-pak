#include <dmi/mi.h>
#include <dmi/sqltypes.h>
#include <inttypes.h>

typedef struct {
    int64_t val;
    uint16_t orig_type;
} any_int_t;

any_int_t *any_int_input(mi_lvarchar *text);
mi_lvarchar *any_int_output(any_int_t *in);

any_int_t *integer_to_any(mi_integer in, MI_FPARAM *fParam);
any_int_t *bigint_to_any(mi_bigint *in, MI_FPARAM *fParam);
any_int_t *smallint_to_any(mi_smallint in, MI_FPARAM *fParam);
any_int_t *boolean_to_any(mi_boolean in, MI_FPARAM *fParam);

mi_integer  any_to_integer(any_int_t *in, MI_FPARAM *fParam);
mi_smallint any_to_smallint(any_int_t *in, MI_FPARAM *fParam);
mi_bigint  *any_to_bigint(any_int_t *in, MI_FPARAM *fParam);
mi_boolean  any_to_boolean(any_int_t *in, MI_FPARAM *fParam);
