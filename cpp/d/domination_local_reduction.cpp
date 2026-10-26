#include <cstddef>
#include <cstdint>

static void put_i64(uint8_t *out, int64_t x) {
    uint64_t b=static_cast<uint64_t>(x);
    for(size_t i=0;i<8;++i) out[i]=static_cast<uint8_t>(b>>(8*i));
}

extern "C" int64_t domination_local_reduction(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if(!input || length<3 || length>135) return -1;
    int64_t n0=input[0],m0=input[1],p0=input[2];
    if(n0<1 || n0>12 || m0<0 || m0>66 || p0<0 || p0>=n0 || length!=3+2*static_cast<size_t>(m0)) return -1;
    size_t n=static_cast<size_t>(n0),m=static_cast<size_t>(m0),p=static_cast<size_t>(p0);
    bool a[12][12]{};
    for(size_t e=0;e<m;++e){ int64_t u0=input[3+2*e],v0=input[4+2*e];
        if(u0<0 || v0<=u0 || v0>=n0) return -1;
        size_t u=static_cast<size_t>(u0),v=static_cast<size_t>(v0); if(a[u][v]) return -1; a[u][v]=a[v][u]=true; }
    bool closed[12]{},exit[12]{},guard[12]{},prisoner[12]{}; closed[p]=true;
    for(size_t u=0;u<n;++u) if(a[p][u]) closed[u]=true;
    for(size_t u=0;u<n;++u) if(a[p][u]) for(size_t x=0;x<n;++x) if(a[u][x]&&!closed[x]){exit[u]=true;break;}
    for(size_t u=0;u<n;++u) if(a[p][u]&&!exit[u]) for(size_t x=0;x<n;++x) if(exit[x]&&a[u][x]){guard[u]=true;break;}
    size_t npr=0; for(size_t u=0;u<n;++u) if(a[p][u]&&!exit[u]&&!guard[u]){prisoner[u]=true;++npr;}
    if(npr==0) return -1;
    size_t ids[12],kept=0; int remap[12];
    for(size_t u=0;u<n;++u){remap[u]=-1;if(!guard[u]&&!prisoner[u]){ids[kept]=u;remap[u]=static_cast<int>(kept++);}}
    size_t k=kept+1,leaf=k-1; int64_t words[25]{}; words[0]=static_cast<int64_t>(k);
    for(size_t i=0;i<kept;++i) words[1+i]=static_cast<int64_t>(ids[i]); words[1+kept]=-1;
    for(size_t i=0;i<kept;++i) for(size_t j=0;j<kept;++j) if(a[ids[i]][ids[j]]) words[1+k+i]|=static_cast<int64_t>(uint64_t{1}<<j);
    words[1+k+static_cast<size_t>(remap[p])]|=static_cast<int64_t>(uint64_t{1}<<leaf);
    words[1+k+leaf]=static_cast<int64_t>(uint64_t{1}<<static_cast<size_t>(remap[p]));
    size_t count=1+2*k,bytes=count*8; if(!output||capacity<bytes)return -2;
    for(size_t i=0;i<count;++i)put_i64(output+8*i,words[i]); return static_cast<int64_t>(bytes);
}
