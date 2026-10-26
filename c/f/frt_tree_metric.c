#include <stddef.h>
#include <stdint.h>

static int within(int64_t d, int64_t beta, int level) {
    if (level >= 0) return d * 1024 <= beta * (INT64_C(1) << level);
    return d * 1024 * (INT64_C(1) << -level) <= beta;
}
static void put_i64(uint8_t *out, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[b] = (uint8_t)(bits >> (8 * b));
}

int64_t frt_tree_metric(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 8 || length > 74) return -1;
    int64_t n0 = input[0], beta = input[1];
    if (n0 < 2 || n0 > 8 || beta < 1024 || beta > 2047) return -1;
    size_t n = (size_t)n0;
    if (length != 2 + n + n*n) return -1;
    size_t perm[8]; uint8_t seen[8] = {0};
    for (size_t i = 0; i < n; ++i) {
        int64_t p = input[2+i];
        if (p < 0 || p >= n0 || seen[p]) return -1;
        seen[p] = 1; perm[i] = (size_t)p;
    }
    int64_t d[8][8] = {{0}}, maxd = 0;
    size_t base = 2+n;
    for (size_t i=0;i<n;i++) for(size_t j=0;j<n;j++) {
        int64_t x=input[base+i*n+j];
        if(x<0||x>255||(i==j&&x!=0)||(i!=j&&x==0)) return -1;
        d[i][j]=x; if(x>maxd)maxd=x;
    }
    for(size_t i=0;i<n;i++)for(size_t j=0;j<n;j++){
        if(d[i][j]!=d[j][i])return -1;
        for(size_t k=0;k<n;k++)if(d[i][j]>d[i][k]+d[k][j])return -1;
    }
    int high=0; while((INT64_C(1)<<high)<maxd) high++;
    int64_t staged[64]={0}; uint16_t clusters[256], next[256];
    size_t count=1; clusters[0]=(uint16_t)((1u<<n)-1u);
    for(int level=high;level>=-10;--level){
        size_t next_count=0;
        int64_t tree_distance=INT64_C(1)<<(level+13);
        for(size_t ci=0;ci<count;ci++){
            uint16_t remaining=clusters[ci], done=0;
            while(remaining){
                size_t center=n;
                for(size_t p=0;p<n;p++)if(remaining&(1u<<perm[p])){center=perm[p];break;}
                if(center==n)return -1;
                uint16_t child=0;
                for(size_t v=0;v<n;v++)if((remaining&(1u<<v))&&within(d[center][v],beta,level))child|=(uint16_t)(1u<<v);
                if(!child)child=(uint16_t)(1u<<center);
                for(size_t u=0;u<n;u++)if(done&(1u<<u))for(size_t v=0;v<n;v++)if(child&(1u<<v))
                    staged[u*n+v]=staged[v*n+u]=tree_distance;
                done|=child; remaining=(uint16_t)(remaining&~child);
                if(next_count>=256)return -1; next[next_count++]=child;
            }
        }
        for(size_t i=0;i<next_count;i++)clusters[i]=next[i]; count=next_count;
    }
    size_t bytes=8*n*n;
    if(!output||capacity<bytes)return -2;
    for(size_t i=0;i<n*n;i++)put_i64(output+8*i,staged[i]);
    return (int64_t)bytes;
}
