#include <stddef.h>
#include <stdint.h>
int64_t euler(const int64_t *v, size_t n) {
    if (!v || n < 4 || n > 516 || v[0] < 1 || v[0] > 32 || v[1] < 0 || v[1] >= v[0] || v[2] < 0 || v[2] >= v[0] || v[3] < 0 || v[3] > 256 || n != 4 + 2 * (size_t)v[3]) return -2;
    size_t count=(size_t)v[0], source=(size_t)v[1], dest=(size_t)v[2], edges=(size_t)v[3];
    uint64_t adj[32]={0}; int degree[32]={0};
    for(size_t i=0;i<edges;i++){int64_t x=v[4+2*i],y=v[5+2*i];if(x<0||y<0||x>=v[0]||y>=v[0]||x==y)return -2;uint64_t bitx=UINT64_C(1)<<(size_t)x,bity=UINT64_C(1)<<(size_t)y;if((adj[x]&bity)!=0)return -2;adj[x]|=bity;adj[y]|=bitx;degree[x]++;degree[y]++;}
    int odd=0;for(size_t i=0;i<count;i++){int want=(source==dest)?0:(i==source||i==dest);if((degree[i]&1)!=want)return 0;if(degree[i]&1)odd++;}
    return odd==(source==dest?0:2);
}
