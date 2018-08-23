//
//  GJPlatformHeader.h
//  GJQueue
//
//  Created by melot on 2017/4/28.
//  Copyright © 2017年 MinorUncle. All rights reserved.
//

#ifndef GJPlatformHeader_h
#define GJPlatformHeader_h

#define MENORY_CHECK 1
#define CLOSE_WHILE_STREAM_COMPLETE 0
#define DEFAULT_TRACKER __func__

#include <stdio.h>


#define GTrue (GInt8)1
#define GFalse (GInt8)0
#define GNULL NULL

#define GINT8_MAX 127
#define GINT8_MIN -127
#define GUINT8_MAX 255
#define GUINT8_MIN 0

#define GINT16_MAX 32767
#define GINT16_MIN -32767
#define GUINT16_MAX 65535
#define GUINT16_MIN 0

#define GINT32_MAX 2147483647
#define GINT32_MIN -2147483647
#define GUINT32_MAX 4294967296
#define GUINT32_MIN 0

#define GINT64_MAX 9223372036854775807LL
#define GINT64_MIN -9223372036854775807LL
#define GUINT64_MAX (GINT64_MAX<<1+1)
#define GUINT64_MIN 0

typedef uint8_t             GUInt8;
typedef int8_t              GInt8;
typedef uint16_t            GUInt16;
typedef int16_t             GInt16;
typedef uint32_t            GUInt32;
typedef int32_t             GInt32;
typedef uint64_t            GUInt64;
typedef int64_t             GInt64;
typedef int                 GInt;

typedef long                GLong;
typedef unsigned long       GULong;
typedef float               GFloat32;
typedef double              GFloat64;
typedef GInt8               GBool;
typedef char                GChar;
typedef unsigned char       GUChar;

typedef void                GVoid;
typedef void*               GHandle;

typedef GInt64              GTimeValue;
typedef GInt32              GTimeScale;

typedef size_t              GSize_t;

typedef struct _TIME{
    GTimeValue    value;
    GTimeScale    scale;
}GTime;

static inline GTime GTimeMake(GTimeValue value, GTimeScale scale)
{
    GTime time; time.value = value; time.scale = scale; return time;
}

static inline GTime GTimeSubtract(GTime minuend, GTime subtrahend)
{
    GTime time; time.value = minuend.value - subtrahend.value*minuend.scale/subtrahend.scale;time.scale = minuend.scale; return time;
}

static inline GFloat64 GTimeSubtractSecondValue(GTime minuend, GTime subtrahend)
{
     return minuend.value*1.0/subtrahend.scale - subtrahend.value*1.0/subtrahend.scale;
}

static inline GLong GTimeSubtractMSValue(GTime minuend, GTime subtrahend)
{
    return minuend.value*1000/minuend.scale - subtrahend.value*1000/subtrahend.scale;
}

static inline GTime GTimeAdd(GTime addend1, GTime addend2)
{
    GTime time; time.value = addend1.value + addend2.value*addend1.scale/addend2.scale;time.scale = addend1.scale; return time;
}

static inline GFloat64 GTimeSencondValue(GTime time)
{
     return (GFloat64)time.value/time.scale;
}

static inline GLong GTimeMSValue(GTime time)
{
    return time.value*1000/time.scale;
}
//typedef int64_t             GTime;
static inline GTime GInvalidTime()
{
    GTime time; time.value = time.scale = 0; return time;
}

#define G_TIME_INVALID GInvalidTime()
#define G_TIME_IS_INVALID(T)      ((T).scale == 0)

typedef int32_t             GResult;
#define GOK                 0
#define GERR_NOMEM          1
#define GERR_TIMEDOUT       2



#define GMIN(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })
#define GMAX(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __b : __a; })
#define GFloatEqual(A,B)({GFloat32 d = (GFloat32)A - (GFloat32)B;d > -0.00001 && d < 0.00001;})
#if defined( __cplusplus )
#   define DEFAULT_PARAM(x) =x
#else
#   define DEFAULT_PARAM(x)
#endif

#endif /* GJPlatformHeader_h */
