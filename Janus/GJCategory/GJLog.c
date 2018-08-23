
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include <stdlib.h>

#include "GJLog.h"
#include <time.h>
#include <sys/time.h>


#define MAX_PRINT_LEN	2048

GJClass* defaultDebug = (GJClass*)&Default_DEBUG;

static FILE *fmsg;

static GJ_LogCallback gj_log_default, *cb = gj_log_default;

static const char *levels[] = {"GJ_NONE","GJ_FORBID","GJ_ERROR", "GJ_WARNING", "GJ_DEBUG","GJ_INFO","GJ_ALL"};
static const GJClass*  debugClass[] = {&Default_NONE,&Default_FORBID,&Default_ERROR,&Default_WARNING,&Default_DEBUG,&Default_INFO,&Default_ALL};
inline static GVoid gj_log_default(GJClass* dClass,GJ_LogLevel level ,const char *pre, const char *format, va_list vl)
{
#ifdef GJ_DEBUG
    GJAssert(dClass != GNULL, "dClass不能为null,在本文件转换");
    char str[MAX_PRINT_LEN]="";
    vsnprintf(str, MAX_PRINT_LEN-1, format, vl);
    if ( !fmsg ) fmsg = stderr;
    struct tm *local;
    
    struct timeval t;
    gettimeofday(&t,NULL);
    local=localtime(&t.tv_sec);
    if (dClass->className != GNULL) {
        fprintf(fmsg, "[%02d:%02d:%02d:%03d][%s][%s][%s]:%s\n",local->tm_hour,local->tm_min,local->tm_sec,t.tv_usec/1000,levels[level],dClass->className,pre, str);
    }else{
        fprintf(fmsg, "[%02d:%02d:%02d:%03d][%s][%s]:%s\n",local->tm_hour,local->tm_min,local->tm_sec,t.tv_usec/1000,levels[level],pre, str);
    }
    fflush(fmsg);

    if (level == GJ_LOGFORBID && dClass->dLevel >= GJ_LOGDEBUG) {
        assert(0);
    }
#endif
}

GVoid GJ_LogSetOutput(char *file)
{
//    fmsg = file;
}

GVoid GJ_LogSetLevel(GJ_LogLevel level)
{
#ifdef GJ_DEBUG
	defaultDebug = (GJClass*)(debugClass[level]);
#else
    if ( !fmsg ) fmsg = stderr;
    fprintf(fmsg, "ERROR:%s设置错误，请重新编译GJLiveLog,并在此之前#define GJ_DEBUG\n", levels[level]);
    fflush(fmsg);
#endif
}

GVoid GJ_LogSetCallback(GJ_LogCallback *cbp)
{
	cb = cbp;
}

GJ_LogLevel GJ_LogGetLevel()
{
	return defaultDebug->dLevel;
}

inline GVoid GJ_Log(const GVoid* logClass, GJ_LogLevel level,const char *pre,const char *format, ...)
{
#ifdef GJ_DEBUG
    GJClass* dClass = defaultDebug;
    if (logClass != GNULL) {
        dClass = (GJClass*)logClass;
    }
    if ( level <= dClass->dLevel && format != GNULL) {
        
        va_list args;
        va_start(args, format);
        cb(dClass,level, pre, format, args);
        va_end(args);
    }
#endif
}

static const char hexdig[] = "0123456789abcdef";

inline GVoid GJ_LogHex(GJ_LogLevel level, const GUInt8 *data, GUInt32 len)
{
#ifdef GJ_DEBUG

	GUInt32 i;
	char line[50], *ptr;

	if ( level > defaultDebug->dLevel )
		return;

	ptr = line;

	for(i=0; i<len; i++) {
		*ptr++ = hexdig[0x0f & (data[i] >> 4)];
		*ptr++ = hexdig[0x0f & data[i]];
		if ((i & 0x0f) == 0x0f) {
			*ptr = '\0';
			ptr = line;
            GJ_Log(defaultDebug,level, "GJ_LogHex","%s", (char*)line);
		} else {
			*ptr++ = ' ';
		}
	}
	if (i & 0x0f) {
		*ptr = '\0';
		GJ_Log(defaultDebug,level,"GJ_LogHex", "%s", line);
	}
#endif
}

inline GVoid GJ_LogHexString(GJ_LogLevel level, const GUInt8 *data, GUInt32 len)
{
#define BP_OFFSET 9
#define BP_GRAPH 60
#define BP_LEN	80
    
#ifdef GJ_DEBUG
	char	line[BP_LEN];
	GUInt32 i;

	if ( !data || level > defaultDebug->dLevel )
		return;

	/* in case len is zero */
	line[0] = '\0';

	for ( i = 0 ; i < len ; i++ ) {
		GInt32 n = i % 16;
		unsigned off;

		if( !n ) {
			if( i ) GJ_Log(defaultDebug, level,"GJ_LogHexString", "%s", line );
			memset( line, ' ', sizeof(line)-2 );
			line[sizeof(line)-2] = '\0';

			off = i % 0x0ffffU;

			line[2] = hexdig[0x0f & (off >> 12)];
			line[3] = hexdig[0x0f & (off >>  8)];
			line[4] = hexdig[0x0f & (off >>  4)];
			line[5] = hexdig[0x0f & off];
			line[6] = ':';
		}

		off = BP_OFFSET + n*3 + ((n >= 8)?1:0);
		line[off] = hexdig[0x0f & ( data[i] >> 4 )];
		line[off+1] = hexdig[0x0f & data[i]];

		off = BP_GRAPH + n + ((n >= 8)?1:0);

		if ( isprint( data[i] )) {
			line[BP_GRAPH + n] = data[i];
		} else {
			line[BP_GRAPH + n] = '.';
		}
	}

	GJ_Log(defaultDebug, level,"GJ_LogHexString", "%s", line );
#endif
}

GVoid GJ_LogAssert(GInt32 isTrue,const char *pre,const char *format, ...){
    if (isTrue == 0) {
        char str[MAX_PRINT_LEN]="";
        char* fPre  = str;
        GULong strLen = MAX_PRINT_LEN-1;
        if (pre) {
            GULong preLen = strlen(pre);
            strcpy(str, pre);
            str[preLen++]=':';
            fPre = str + preLen;
            strLen -= preLen;
        }
        if (format != GNULL) {
            GInt32 len;
            va_list args;
            va_start(args, format);
            len = vsnprintf(fPre, strLen, format, args);
            va_end(args);
        }

        if ( !fmsg ) fmsg = stderr;
        fprintf(fmsg, "%s\n", str);
        fflush(fmsg);
        if ( defaultDebug->dLevel >= GJ_LOGDEBUG)
            assert(0);
    }
}

GBool GJ_LogCheckResult(GResult result,const char *pre,const char *format, ...){
    if (result != GOK && defaultDebug->dLevel > GJ_LOGNONE) {

        char str[MAX_PRINT_LEN]="";
        va_list args;
        va_start(args, format);
        vsnprintf(str, MAX_PRINT_LEN-1, format, args);
        va_end(args);
        
        if ( !fmsg ) fmsg = stderr;
        struct tm *local;
        time_t t;
        t=time(NULL);
        local=localtime(&t);
        fprintf(fmsg, "[%02d:%02d:%02d][GJ_LOGCHECK][%s]:%s error result:%d\n",local->tm_hour,local->tm_min,local->tm_sec,pre,str,result);
        fflush(fmsg);
    }
    return result == GOK;
}
GBool GJ_LogCheckBool(GBool isTrue,const char *pre,const char *format, ...){
    if (!isTrue && defaultDebug->dLevel > GJ_LOGNONE) {
        
        char str[MAX_PRINT_LEN]="";
        va_list args;
        va_start(args, format);
        vsnprintf(str, MAX_PRINT_LEN-1, format, args);
        va_end(args);
        
        if ( !fmsg ) fmsg = stderr;
        struct tm *local;
        time_t t;
        t=time(NULL);
        local=localtime(&t);
        fprintf(fmsg, "[%02d:%02d:%02d][GJ_LOGCHECK][%s]:%s error\n",local->tm_hour,local->tm_min,local->tm_sec,pre,str);
        fflush(fmsg);
    }
    return isTrue;
}
