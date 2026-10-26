#include <cstddef>
#include <cstdint>

namespace {
bool within(std::int64_t d, std::int64_t beta, int level) {
    if (level >= 0) return d*1024 <= beta*(std::int64_t(1)<<level);
    return d*1024*(std::int64_t(1)<<-level) <= beta;
}
void put_i64(std::uint8_t* out, std::int64_t value) {
    auto bits=static_cast<std::uint64_t>(value);
    for(std::size_t b=0;b<8;b++)out[b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}

extern "C" std::int64_t frt_tree_metric(const std::int64_t* input,std::size_t length,
                                         std::uint8_t* output,std::size_t capacity) {
    if(!input||length<8||length>74)return -1;
    auto n0=input[0], beta=input[1];
    if(n0<2||n0>8||beta<1024||beta>2047)return -1;
    auto n=static_cast<std::size_t>(n0);
    if(length!=2+n+n*n)return -1;
    std::size_t perm[8]{};bool seen[8]{};
    for(std::size_t i=0;i<n;i++){auto p=input[2+i];if(p<0||p>=n0||seen[p])return -1;seen[p]=true;perm[i]=static_cast<std::size_t>(p);}
    std::int64_t d[8][8]{},maxd=0;auto base=2+n;
    for(std::size_t i=0;i<n;i++)for(std::size_t j=0;j<n;j++){auto x=input[base+i*n+j];if(x<0||x>255||(i==j&&x!=0)||(i!=j&&x==0))return -1;d[i][j]=x;if(x>maxd)maxd=x;}
    for(std::size_t i=0;i<n;i++)for(std::size_t j=0;j<n;j++){if(d[i][j]!=d[j][i])return -1;for(std::size_t k=0;k<n;k++)if(d[i][j]>d[i][k]+d[k][j])return -1;}
    int high=0;while((std::int64_t(1)<<high)<maxd)++high;
    std::int64_t staged[64]{};std::uint16_t clusters[256],next[256];std::size_t count=1;clusters[0]=static_cast<std::uint16_t>((1u<<n)-1u);
    for(int level=high;level>=-10;--level){std::size_t next_count=0;auto td=std::int64_t(1)<<(level+13);
        for(std::size_t ci=0;ci<count;ci++){auto remaining=clusters[ci];std::uint16_t done=0;
            while(remaining){std::size_t center=n;for(std::size_t p=0;p<n;p++)if(remaining&(1u<<perm[p])){center=perm[p];break;}if(center==n)return -1;
                std::uint16_t child=0;for(std::size_t v=0;v<n;v++)if((remaining&(1u<<v))&&within(d[center][v],beta,level))child|=static_cast<std::uint16_t>(1u<<v);if(!child)child=static_cast<std::uint16_t>(1u<<center);
                for(std::size_t u=0;u<n;u++)if(done&(1u<<u))for(std::size_t v=0;v<n;v++)if(child&(1u<<v))staged[u*n+v]=staged[v*n+u]=td;
                done|=child;remaining=static_cast<std::uint16_t>(remaining&~child);if(next_count>=256)return -1;next[next_count++]=child;
            }
        }for(std::size_t i=0;i<next_count;i++)clusters[i]=next[i];count=next_count;
    }
    auto bytes=8*n*n;if(!output||capacity<bytes)return -2;for(std::size_t i=0;i<n*n;i++)put_i64(output+8*i,staged[i]);return static_cast<std::int64_t>(bytes);
}
