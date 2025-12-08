// vim: noai:ts=4:sw=4
#include <dmi/mi.h>
#include "../tracing/tracing.h"

#define isNull(x) (NULL == x)
#define notNull(x) (NULL != x)

#define udr_memset(mem,ch,len)		        	byfill( (char*)mem, len, (char)ch )
#define udr_dalloc(type_t,dur)                          (type_t*) mi_dalloc( sizeof(type_t), dur ) 
#define udr_dalloc_range(type_t,count,dur)	        (type_t*) mi_dalloc( sizeof(type_t) * count, dur )

#define udr_alloc(type_t)		                (type_t*) mi_dalloc( sizeof(type_t),PER_COMMAND )
#define udr_alloc_range(type_t,count)		        (type_t*) mi_dalloc( sizeof(type_t) * count,PER_COMMAND)
#define udr_alloc_bytes(num)				(void*) mi_dalloc( num, PER_COMMAND )

/* 
    These are for allocating space for return values, 
    the per_routing lifetime is so they get cleaned up straight 
    away 
*/
#define udr_alloc_ret(type_t)				(type_t*) mi_dalloc( sizeof(type_t),PER_ROUTINE ) 
#define udr_alloc_ret_range(type_t,count)		(type_t*) mi_dalloc( sizeof(type_t) * count,PER_ROUTINE)
#define udr_alloc_ret_bytes(num)			(void*) mi_dalloc( num, PER_ROUTINE )
#define return_enomem(x)        \
        mi_fp_setreturnisnull(fParam, 0, MI_TRUE); \
        mi_db_error_raise( \
            NULL, MI_EXCEPTION,__FILE__ \
            ": UDR Extension emoory allocation failure, Aborting" \
        ); return(x)

#define return_SQLnull(r)   \
    mi_fp_setreturnisnull(fParam,0,1); \
      return(r)


#define notArgNull(fParam,argNum)                 ( mi_fp_argisnull(fParam, argNum) == MI_FALSE )

#define isArgNull(fParam,argNum)                    ( mi_fp_argisnull(fParam, argNum) == MI_TRUE )
#define nvl2Arg(fParam,argNum, not_val, is_val)     ( isArgNull(fParam,argNum) ? is_val : not_val )




#define dur_num_to_name(d) \
        (d == 0) ? "None" : \
        (d == 1) ? "CMD" : \
        (d == 2) ? "STMT_92" : \
        (d == 3) ? "TXT" : \
        (d == 4) ? "Excep" : \
        (d == 5) ? "Sess" : \
        (d == 5) ? "Sys" : \
        (d == 6) ? "ExecStmt" : \
        (d == 7) ? "Cursor" : \
        (d == 8) ? "Conn" : "UnkErr"

#define get_dur(ptr)	dur_num_to_name(mi_get_memptr_duration(ptr))

#define NSEC   (long)1000000000
#define USEC   (long)1000000
#define MSEC   (long)1000

#define FRAC5  (long)100000
#define FRAC4  (long)10000
#define FRAC3  (long)1000
#define FRAC2  (long)100
#define FRAC1  (long)10

/* These are for datetime year to fraction conversions*/
#define DYEAR  (long)10000000000
#define DMON   (long)100000000
#define DDAY   (long)1000000
#define DHOUR  (long)10000
#define DMIN   (long)100

#define int16_to_dec( int_val, dec_ptr )		deccvint(    int_val, dec_ptr )
#define int32_to_dec( int_val, dec_ptr )		deccvlong(   int_val, dec_ptr )
#define int64_to_dec( int_val, dec_ptr )		biginttodec( int_val, dec_ptr )
#define dec_to_int16( dec_ptr, int_ptr )		dectoint(    dec_ptr, int_ptr )
#define dec_to_int32( dec_ptr, int_ptr )		dectolong(   dec_ptr, int_ptr )
#define dec_to_int64( dec_ptr, int_ptr )		bigintcvdec( dec_ptr, int_ptr )


void * get_func_state_ptr(size_t sz, MI_FPARAM *fParam);


mi_integer udr_fn(mi_lvarchar *trc, MI_FPARAM *fParam);

