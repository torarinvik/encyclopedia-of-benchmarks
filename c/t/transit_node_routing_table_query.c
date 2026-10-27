#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t transit_node_routing_table_query(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 11 || length > 86) return -1;
    int64_t q0=input[0], source=input[1], target=input[2], far=input[3];
    if(q0<1||q0>8||source<0||source>=32||target<0||target>=32||far!=1)return -1;
    int q=(int)q0;size_t at=4;
    int64_t nf0=input[at++];if(nf0<1||nf0>4||nf0>q||at+2*(size_t)nf0>length)return -1;
    int nf=(int)nf0;int f[8];int64_t ds[8];
    for(int i=0;i<nf;i++){int64_t u=input[at++],d=input[at++];if(u<0||u>=q||d<0||d>1000000)return -1;for(int j=0;j<i;j++)if(f[j]==u)return -1;f[i]=(int)u;ds[i]=d;}
    if(at>=length)return -1;int64_t nb0=input[at++];if(nb0<1||nb0>4||nb0>q||at+2*(size_t)nb0>length)return -1;
    int nb=(int)nb0;int b[8];int64_t dt[8];
    for(int i=0;i<nb;i++){int64_t v=input[at++],d=input[at++];if(v<0||v>=q||d<0||d>1000000)return -1;for(int j=0;j<i;j++)if(b[j]==v)return -1;b[i]=(int)v;dt[i]=d;}
    if(at+(size_t)q*(size_t)q!=length)return -1;int64_t dtt[8][8]={{0}};
    for(int i=0;i<q;i++)for(int j=0;j<q;j++){int64_t d=input[at++];if(d<0||d>1000000)return -1;dtt[i][j]=d;}
    for(int i=0;i<q;i++)if(dtt[i][i]!=0)return -1;
    int64_t best=INT64_MAX;int bestu=-1,bestv=-1;
    for(int i=0;i<nf;i++)for(int j=0;j<nb;j++){int64_t d=ds[i]+dtt[f[i]][b[j]]+dt[j];if(d<best||(d==best&&(f[i]<bestu||(f[i]==bestu&&b[j]<bestv)))){best=d;bestu=f[i];bestv=b[j];}}
    if(output==NULL||capacity<24)return -2;put_i64(output,0,best);put_i64(output,1,bestu);put_i64(output,2,bestv);return 24;
}
