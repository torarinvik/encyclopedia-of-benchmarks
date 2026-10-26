#include <cstddef>
#include <cstdint>
namespace { void put_i64(std::uint8_t*out,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;i++)out[i]=static_cast<std::uint8_t>(b>>(8*i));} }
extern "C" std::int64_t all_distances_sketch_bottom_k(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
    if(!input||length<6||length>104)return -1;auto n0=input[0],m0=input[1],k0=input[2],s0=input[3];
    if(n0<2||n0>10||m0<0||m0>n0*(n0-1)||k0<1||k0>n0||s0<0||s0>=n0||length!=4+static_cast<std::size_t>(n0)+2*static_cast<std::size_t>(m0))return -1;
    auto n=static_cast<std::size_t>(n0),m=static_cast<std::size_t>(m0),k=static_cast<std::size_t>(k0),source=static_cast<std::size_t>(s0);
    std::int64_t rank[10];bool used[10]{};for(std::size_t i=0;i<n;i++){auto r=input[4+i];if(r<0||r>=n0||used[r])return -1;used[r]=true;rank[i]=r;}
    bool adj[10][10]{};for(std::size_t e=0;e<m;e++){auto u0=input[4+n+2*e],v0=input[5+n+2*e];if(u0<0||u0>=n0||v0<0||v0>=n0||u0==v0)return -1;auto u=static_cast<std::size_t>(u0),v=static_cast<std::size_t>(v0);if(adj[u][v])return -1;adj[u][v]=true;}
    std::int64_t dist[10];for(std::size_t i=0;i<n;i++)dist[i]=-1;std::size_t queue[10],head=0,tail=0;dist[source]=0;queue[tail++]=source;
    while(head<tail){auto u=queue[head++];for(std::size_t v=0;v<n;v++)if(adj[u][v]&&dist[v]<0){dist[v]=dist[u]+1;queue[tail++]=v;}}
    std::int64_t staged[21]{};std::size_t count=0;for(std::size_t d=0;d<n;d++)for(std::size_t v=0;v<n;v++)if(dist[v]==static_cast<std::int64_t>(d)){
        std::size_t less=0;for(std::size_t x=0;x<n;x++)if(dist[x]>=0&&(dist[x]<dist[v]||(dist[x]==dist[v]&&x<=v))&&rank[x]<rank[v])less++;
        if(less<k){staged[1+2*count]=static_cast<std::int64_t>(v);staged[2+2*count]=dist[v];count++;}}
    staged[0]=static_cast<std::int64_t>(count);auto words=1+2*count,bytes=8*words;if(!output||capacity<bytes)return -2;for(std::size_t i=0;i<words;i++)put_i64(output+8*i,staged[i]);return static_cast<std::int64_t>(bytes);
}
