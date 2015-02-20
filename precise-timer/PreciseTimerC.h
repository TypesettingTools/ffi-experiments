#ifndef PRECISETIMERC_H
#define PRECISETIMERC_H

#ifdef __cplusplus
extern "C" {
#endif

struct CPT;
typedef struct CPT CPT;

CPT* startTimer( void );
double getDuration( CPT *pt );
void freeTimer( CPT *pt );

#ifdef __cplusplus
}
#endif

#endif /*PRECISETIMERC_H*/
