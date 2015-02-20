#ifndef DOWNLOADMANAGERC_H
#define DOWNLOADMANAGERC_H

#ifdef __cplusplus
extern "C" {
#endif

struct CDlM;
typedef struct CDlM CDlM;
typedef unsigned int uint;

CDlM*       newDM        ( void );
uint        addDownload  ( CDlM *mgr,           const char *url,
                           const char *outfile, const char *sha1 );
double      progress     ( CDlM *mgr );
int         busy         ( CDlM *mgr );
int         checkDownload( CDlM *mgr, uint i );
const char* getError     ( CDlM *mgr, uint i );
void        terminate    ( CDlM *mgr );
void        clear        ( CDlM *mgr );
void        freeDM       ( CDlM *mgr );

#ifdef __cplusplus
}
#endif

#endif /*DOWNLOADMANAGERC_H*/
