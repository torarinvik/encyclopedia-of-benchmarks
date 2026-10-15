/* Return the Ruby BFS result collections with their insertion order preserved. */
#include <cstddef>
#include <cstdint>
namespace {void put(std::uint8_t*out,std::size_t word,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[word*8+b]=static_cast<std::uint8_t>(bits>>(8*b));}}
extern "C" std::int64_t bfs_result_tree(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept{
 if(!in||len<3)return -1;auto nv=in[0],mv=in[1],sv=in[2];if(nv<1||nv>32||mv<0||mv>126||sv<0||sv>=nv||len!=static_cast<std::size_t>(3+2*mv))return -1;auto n=static_cast<std::size_t>(nv),m=static_cast<std::size_t>(mv),start=static_cast<std::size_t>(sv);
 std::size_t adj[32][126]{},degree[32]{};bool seen[32]{};std::int64_t parent[32],distance[32];std::size_t queue[32],order[32];for(std::size_t v=0;v<n;++v){parent[v]=-1;distance[v]=-1;}
 for(std::size_t e=0;e<m;++e){auto a=in[3+2*e],b=in[4+2*e];if(a<0||a>=nv||b<0||b>=nv)return -1;adj[static_cast<std::size_t>(a)][degree[a]++]=static_cast<std::size_t>(b);}
 std::size_t head=0,tail=0,count=0;seen[start]=true;distance[start]=0;queue[tail++]=start;while(head<tail){auto v=queue[head++];order[count++]=v;for(std::size_t j=0;j<degree[v];++j){auto w=adj[v][j];if(!seen[w]){seen[w]=true;parent[w]=static_cast<std::int64_t>(v);distance[w]=distance[v]+1;queue[tail++]=w;}}}
 const auto words=4+6*count;if(!out||cap<words*8)return -2;std::size_t k=0;put(out,k++,static_cast<std::int64_t>(count));for(std::size_t i=0;i<count;++i)put(out,k++,static_cast<std::int64_t>(order[i]));put(out,k++,static_cast<std::int64_t>(count));for(std::size_t i=0;i<count;++i)put(out,k++,static_cast<std::int64_t>(order[i]));put(out,k++,static_cast<std::int64_t>(count));for(std::size_t i=0;i<count;++i){auto v=order[i];put(out,k++,static_cast<std::int64_t>(v));put(out,k++,parent[v]);}put(out,k++,static_cast<std::int64_t>(count));for(std::size_t i=0;i<count;++i){auto v=order[i];put(out,k++,static_cast<std::int64_t>(v));put(out,k++,distance[v]);}return static_cast<std::int64_t>(words*8);
}
