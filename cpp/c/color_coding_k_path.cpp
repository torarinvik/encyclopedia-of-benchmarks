/* Bounded colorful k-vertex path existence via subset/endpoint dynamic programming. */
#include <cstddef>
#include <cstdint>

extern "C" int64_t color_coding_k_path(const int64_t *values, size_t length,
                                        uint8_t *output, size_t output_capacity) {
    if (!values) return -2;
    if (length < 3 || length > 147) return -1;
    auto nv=values[0], mv=values[1], kv=values[2];
    if (nv<1 || nv>12 || mv<0 || mv>66 || kv<1 || kv>6 || kv>nv) return -1;
    size_t n=nv,m=mv,k=kv,split=3+n;
    if (length!=split+2*m) return -1;
    size_t colors[12]; uint16_t adj[12]={};
    for(size_t v=0;v<n;++v){ if(values[3+v]<0||values[3+v]>=kv)return -1; colors[v]=values[3+v]; }
    for(size_t e=0;e<m;++e){ auto av=values[split+2*e],bv=values[split+2*e+1];
        if(av<0||bv<0||av>=nv||bv>=nv||av==bv)return -1;
        size_t a=av,b=bv; if(adj[a]&(1u<<b))return -1; adj[a]|=1u<<b;adj[b]|=1u<<a;
    }
    uint8_t dp[64][12]={}; for(size_t v=0;v<n;++v)dp[1u<<colors[v]][v]=1;
    size_t full=(1u<<k)-1; bool found=false;
    for(size_t mask=1;mask<=full&&!found;++mask)for(size_t v=0;v<n&&!found;++v)if(dp[mask][v]){
        if(mask==full){found=true;break;}
        for(size_t u=0;u<n;++u)if((adj[v]&(1u<<u))&&!(mask&(1u<<colors[u])))dp[mask|(1u<<colors[u])][u]=1;
    }
    if(output_capacity<8||!output)return -2;
    uint64_t ans=found?1:0;for(size_t i=0;i<8;++i)output[i]=(ans>>(8*i))&255;return 8;
}
