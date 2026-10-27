#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N=16,M=24,L=74;
void put32(std::uint8_t *out,std::size_t pos,std::int32_t value){auto bits=static_cast<std::uint32_t>(value);for(std::size_t j=0;j<4;++j){out[pos+j]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}

extern "C" std::int64_t randomized_contraction_edge_sampling(const std::int64_t *input,
    std::size_t length,std::uint8_t *output,std::size_t capacity) noexcept {
    if(!input||length<5||length>L)return -1;
    const auto n64=input[0],m64=input[1];
    if(n64<2||n64>N||m64<n64-1||m64>M||length!=2+3*static_cast<std::size_t>(m64))return -1;
    const auto n=static_cast<std::size_t>(n64),m=static_cast<std::size_t>(m64);
    std::int64_t u[M]{},v[M]{},bit[M]{};
    for(std::size_t i=0;i<m;++i){u[i]=input[2+3*i];v[i]=input[3+3*i];bit[i]=input[4+3*i];if(u[i]<0||u[i]>=v[i]||v[i]>=n64||(bit[i]!=0&&bit[i]!=1))return -1;for(std::size_t j=0;j<i;++j)if(u[i]==u[j]&&v[i]==v[j])return -1;}
    bool seen[N]{};std::size_t queue[N]{},head=0,tail=1;queue[0]=0;seen[0]=true;
    while(head<tail){auto current=queue[head++];for(std::size_t e=0;e<m;++e){std::int64_t next=-1;if(static_cast<std::size_t>(u[e])==current)next=v[e];else if(static_cast<std::size_t>(v[e])==current)next=u[e];if(next>=0&&!seen[static_cast<std::size_t>(next)]){seen[static_cast<std::size_t>(next)]=true;queue[tail++]=static_cast<std::size_t>(next);}}}
    if(tail!=n)return -1;
    std::size_t parent[N]{};for(std::size_t i=0;i<n;++i)parent[i]=i;
    for(std::size_t e=0;e<m;++e)if(bit[e]){auto a=static_cast<std::size_t>(u[e]),b=static_cast<std::size_t>(v[e]);while(parent[a]!=a)a=parent[a];while(parent[b]!=b)b=parent[b];if(a!=b)parent[b]=a;}
    std::size_t minimum[N];for(std::size_t i=0;i<n;++i)minimum[i]=n;
    for(std::size_t vertex=0;vertex<n;++vertex){auto root=vertex;while(parent[root]!=root)root=parent[root];if(vertex<minimum[root])minimum[root]=vertex;}
    const auto bytes=4*n;if(!output||capacity<bytes)return -2;
    std::uint8_t staged[4*N]{};
    for(std::size_t vertex=0;vertex<n;++vertex){auto root=vertex;while(parent[root]!=root)root=parent[root];put32(staged,4*vertex,static_cast<std::int32_t>(minimum[root]));}
    for(std::size_t i=0;i<bytes;++i)output[i]=staged[i];return static_cast<std::int64_t>(bytes);
}
