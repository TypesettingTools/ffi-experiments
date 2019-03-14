/*
SHA-1 in C by Steve Reid
100% Public Domain
*/

#ifndef __DM_SHA1_H
#define __DM_SHA1_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef struct {
    uint32_t state[5];
    uint32_t count[2];
    uint8_t  buffer[64];
} DM_SHA1_CTX;

#define DM_SHA1_DIGEST_SIZE 20

void DM_SHA1_Init(DM_SHA1_CTX* context);
void DM_SHA1_Update(DM_SHA1_CTX* context, const uint8_t* data, const size_t len);
void DM_SHA1_Final(DM_SHA1_CTX* context, uint8_t digest[DM_SHA1_DIGEST_SIZE]);

#ifdef __cplusplus
}
#endif

#endif /* __DM_SHA1_H */
