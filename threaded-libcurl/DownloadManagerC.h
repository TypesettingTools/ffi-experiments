#ifndef DOWNLOADMANAGERC_H
#define DOWNLOADMANAGERC_H

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif /*_WIN32*/

#ifdef __cplusplus
extern "C" {
#endif

struct CDlM;
typedef struct CDlM CDlM;
typedef unsigned int uint;

EXPORT CDlM*       newDM        ( void );
EXPORT uint        addDownload  ( CDlM *mgr,           const char *url,
                                  const char *outfile, const char *sha1,
                                  char **etag );
EXPORT double      progress     ( CDlM *mgr );
EXPORT int         busy         ( CDlM *mgr );
EXPORT int         checkDownload( CDlM *mgr, uint i );
EXPORT const char* getError     ( CDlM *mgr, uint i );
EXPORT void        terminate    ( CDlM *mgr );
EXPORT void        clear        ( CDlM *mgr );
EXPORT const char* getFileSHA1  ( const char *filename );
EXPORT const char* getStringSHA1( const char *string );
EXPORT uint        version      ( void );
EXPORT void        freeDM       ( CDlM *mgr );

#ifdef __cplusplus
}
#endif

#endif /*DOWNLOADMANAGERC_H*/
