/* Compute all source-zero distances with a small Dijkstra frontier. */
#include <cstddef>
#include <cstdint>
namespace {void put(std::uint8_t*out,std::size_t i,std::int64_t v){auto bits=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;++b)out[i*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}}
extern "C" std::int64_t dijkstra_positive_connected(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept{
 if(!in||len<2)return -1;auto nv=in[0],mv=in[1];if(nv<2||nv>4||mv<0||mv>6||len!=static_cast<std::size_t>(2+3*mv))return -1;auto n=static_cast<std::size_t>(nv),m=static_cast<std::size_t>(mv);if(m<n-1||m>n*(n-1)/2)return -1;
 int weight[4][4]{},adj[4][4]{},degree[4]{},neighbors[4][6]{};for(std::size_t e=0;e<m;++e){auto u=in[2+3*e],v=in[3+3*e],w=in[4+3*e];if(u<0||u>=nv||v<0||v>=nv||u==v||w<1||w>255||adj[u][v])return -1;adj[u][v]=adj[v][u]=1;weight[u][v]=weight[v][u]=static_cast<int>(w);neighbors[u][degree[u]++]=static_cast<int>(v);neighbors[v][degree[v]++]=static_cast<int>(u);}
 bool seen[4]{};int stack[4],top=0;stack[top++]=0;seen[0]=true;while(top){auto u=stack[--top];for(int i=0;i<degree[u];++i){auto v=neighbors[u][i];if(!seen[v]){seen[v]=true;stack[top++]=v;}}}for(std::size_t i=0;i<n;++i)if(!seen[i])return -1;
 std::int64_t dist[4]={INT64_MAX,INT64_MAX,INT64_MAX,INT64_MAX};bool done[4]{};dist[0]=0;for(std::size_t step=0;step<n;++step){int u=-1;for(std::size_t i=0;i<n;++i)if(!done[i]&&(u<0||dist[i]<dist[u]))u=static_cast<int>(i);if(u<0)break;done[u]=true;for(int j=0;j<degree[u];++j){int v=neighbors[u][j];if(!done[v]&&dist[u]+weight[u][v]<dist[v])dist[v]=dist[u]+weight[u][v];}}
 if(!out||cap<n*8)return -2;for(std::size_t i=0;i<n;++i)put(out,i,dist[i]);return static_cast<std::int64_t>(n*8);
}
