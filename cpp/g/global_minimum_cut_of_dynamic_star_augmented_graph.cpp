#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int MAX_N=16,MAX_M=64,MAX_Q=32,MAX_V=17,MAX_INPUT=276,MAX_OUTPUT=256;
constexpr std::int64_t MAX_W=1000000;
void store_le(std::uint8_t *out,std::size_t at,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;++i){out[at+i]=static_cast<std::uint8_t>(b&255u);b>>=8;}}
std::int64_t stoer_wagner(std::size_t n,const std::int64_t *spokes,std::size_t m,const std::int64_t *eu,const std::int64_t *ev,const std::int64_t *ew){
    const auto vc=n+1;std::int64_t w[MAX_V][MAX_V]{};for(std::size_t e=0;e<m;++e){auto u=static_cast<std::size_t>(eu[e]),v=static_cast<std::size_t>(ev[e]);w[u][v]+=ew[e];w[v][u]+=ew[e];}
    for(std::size_t u=0;u<n;++u){w[u][n]+=spokes[u];w[n][u]+=spokes[u];}std::size_t active[MAX_V],count=vc;for(std::size_t i=0;i<vc;++i)active[i]=i;auto best=std::numeric_limits<std::int64_t>::max();
    while(count>1){bool used[MAX_V]{};std::int64_t connection[MAX_V]{};int previous=-1;
        for(std::size_t step=0;step<count;++step){int selected=-1;for(std::size_t z=0;z<count;++z){int u=static_cast<int>(active[z]);if(!used[u]&&(selected<0||connection[u]>connection[selected]||(connection[u]==connection[selected]&&u<selected)))selected=u;}
            if(step+1==count){best=std::min(best,connection[selected]);for(std::size_t z=0;z<count;++z){int u=static_cast<int>(active[z]);if(u!=selected&&u!=previous){w[previous][u]+=w[selected][u];w[u][previous]=w[previous][u];}}std::size_t pos=0;while(active[pos]!=static_cast<std::size_t>(selected))++pos;for(std::size_t z=pos+1;z<count;++z)active[z-1]=active[z];--count;break;}
            used[selected]=true;previous=selected;for(std::size_t z=0;z<count;++z){int u=static_cast<int>(active[z]);if(!used[u])connection[u]+=w[selected][u];}
        }
    }return best;
}
}
extern "C" std::int64_t global_minimum_cut_of_dynamic_star_augmented_graph(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity){
    if(!input||length<3||length>MAX_INPUT)return -1;auto n0=input[0],m0=input[1],q0=input[2];if(n0<1||n0>MAX_N||m0<0||m0>MAX_M||m0>n0*(n0-1)/2||q0<1||q0>MAX_Q)return -1;
    auto n=static_cast<std::size_t>(n0),m=static_cast<std::size_t>(m0),q=static_cast<std::size_t>(q0);if(length!=3+n+3*m+2*q)return -1;std::size_t pos=3;std::int64_t spokes[MAX_N],eu[MAX_M],ev[MAX_M],ew[MAX_M];
    for(std::size_t i=0;i<n;++i){spokes[i]=input[pos++];if(spokes[i]<0||spokes[i]>MAX_W)return -1;}bool seen[MAX_N][MAX_N]{};
    for(std::size_t e=0;e<m;++e){auto u=input[pos++],v=input[pos++],weight=input[pos++];if(u<0||u>=n0||v<0||v>=n0||u==v||weight<0||weight>MAX_W)return -1;auto a=static_cast<std::size_t>(std::min(u,v)),b=static_cast<std::size_t>(std::max(u,v));if(seen[a][b])return -1;seen[a][b]=true;eu[e]=u;ev[e]=v;ew[e]=weight;}
    std::int64_t ux[MAX_Q],uy[MAX_Q];for(std::size_t i=0;i<q;++i){ux[i]=input[pos++];uy[i]=input[pos++];if(ux[i]<0||ux[i]>=n0||uy[i]<0||uy[i]>MAX_W)return -1;}
    auto bytes=8*q;if(bytes>MAX_OUTPUT)return -1;if(!output||capacity<bytes)return -2;std::int64_t ans[MAX_Q];for(std::size_t i=0;i<q;++i){spokes[static_cast<std::size_t>(ux[i])]=uy[i];ans[i]=stoer_wagner(n,spokes,m,eu,ev,ew);}for(std::size_t i=0;i<q;++i)store_le(output,8*i,ans[i]);return static_cast<std::int64_t>(bytes);
}
