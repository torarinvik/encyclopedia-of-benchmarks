#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_N 8
#define MAX_NNZ 64
#define MAX_INPUT 164
#define MAX_OUTPUT 36

static float decode(int64_t x) { return (float)x / 1000000.0f; }
static void put32(uint8_t *p, uint32_t x) { p[0]=(uint8_t)x; p[1]=(uint8_t)(x>>8); p[2]=(uint8_t)(x>>16); p[3]=(uint8_t)(x>>24); }

int64_t parboil_spmv_jds(const int64_t *in, size_t len, uint8_t *out, size_t cap)
{
    int64_t rows[MAX_N], perm[MAX_N], ptr[MAX_N+1], col[MAX_NNZ], data[MAX_NNZ], vec[MAX_N];
    uint8_t staged[MAX_OUTPUT];
    size_t n, depth, nnz, p, k, i;
    size_t lengths[MAX_N], prefix[MAX_N+1];
    float y[MAX_N];
    if (in == NULL || len < 3 || len > MAX_INPUT) return -1;
    if (in[0] < 1 || in[0] > MAX_N || in[1] < 1 || in[1] > MAX_N || in[2] < 1 || in[2] > MAX_NNZ) return -1;
    n=(size_t)in[0]; depth=(size_t)in[1]; nnz=(size_t)in[2];
    if (len != 4+3*n+depth+2*nnz) return -1;
    p=3;
    for(i=0;i<n;i++) { if(in[p]<0 || in[p]>(int64_t)depth) return -1; rows[i]=in[p++]; }
    if(rows[0]!=(int64_t)depth) return -1;
    for(i=1;i<n;i++) if(rows[i]>rows[i-1]) return -1;
    for(i=0;i<n;i++) perm[i]=in[p++];
    for(i=0;i<n;i++) { if(perm[i]<0 || perm[i]>=(int64_t)n) return -1; for(size_t j=0;j<i;j++) if(perm[j]==perm[i]) return -1; }
    for(k=0;k<=depth;k++) ptr[k]=in[p++];
    for(i=0;i<nnz;i++) col[i]=in[p++];
    for(i=0;i<nnz;i++) data[i]=in[p++];
    for(i=0;i<n;i++) vec[i]=in[p++];
    if(p!=len) return -1;
    for(k=0;k<depth;k++) { size_t count=0; for(i=0;i<n;i++) if(rows[i]>(int64_t)k) count++; lengths[k]=count; }
    prefix[0]=0; for(k=0;k<depth;k++) prefix[k+1]=prefix[k]+lengths[k];
    if(prefix[depth]!=nnz) return -1;
    for(k=0;k<=depth;k++) if(ptr[k]!=(int64_t)prefix[k]) return -1;
    for(i=0;i<nnz;i++) if(col[i]<0 || col[i]>=(int64_t)n) return -1;
    for(i=0;i<nnz;i++) if(data[i]<-1000000 || data[i]>1000000) return -1;
    for(i=0;i<n;i++) if(vec[i]<-1000000 || vec[i]>1000000) return -1;
    if(out==NULL || cap<4+4*n) return -2;
    for(i=0;i<n;i++) { float acc=0.0f; for(k=0;k<(size_t)rows[i];k++) { size_t j=(size_t)ptr[k]+i; float a=decode(data[j]); float b=decode(vec[(size_t)col[j]]); float product=a*b; acc=acc+product; } y[(size_t)perm[i]]=acc; }
    put32(staged,(uint32_t)n); for(i=0;i<n;i++) { uint32_t bits; memcpy(&bits,&y[i],4); put32(staged+4+4*i,bits); }
    memcpy(out,staged,4+4*n); return (int64_t)(4+4*n);
}
