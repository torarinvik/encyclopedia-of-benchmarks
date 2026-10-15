#include <cstddef>
#include <cstdint>

namespace {
constexpr int V=8,E=24,P=1000;
constexpr std::size_t OUT=8+P*(V+1)*8;
void put_i64(std::uint8_t *o,std::size_t at,std::int64_t x){std::uint64_t u=static_cast<std::uint64_t>(x);for(int b=0;b<8;++b){o[at+b]=static_cast<std::uint8_t>(u);u>>=8;}}
struct Search { int (*adj)[E]; int *degree; bool *visited; int *path; int depth,target; std::int64_t *count; std::uint8_t *out; std::size_t *at; bool overflow; };
void dfs(Search &s,int u){if(s.overflow)return;if(u==s.target){if(*s.count==P){s.overflow=true;return;}put_i64(s.out,*s.at,s.depth);*s.at+=8;for(int i=0;i<s.depth;++i){put_i64(s.out,*s.at,s.path[i]);*s.at+=8;}++*s.count;return;}s.visited[u]=true;for(int i=0;i<s.degree[u]&&!s.overflow;++i){int v=s.adj[u][i];if(!s.visited[v]){s.path[s.depth++]=v;dfs(s,v);--s.depth;}}s.visited[u]=false;}
}
extern "C" std::int64_t all_paths_from_source_to_target(const std::int64_t *v,std::size_t n,std::uint8_t *output,std::size_t capacity){
    if(!v||n<4||n>52||v[0]<1||v[0]>V||v[1]<0||v[1]>E)return -1;int vertices=int(v[0]),edges=int(v[1]);if(v[2]<0||v[2]>=vertices||v[3]<0||v[3]>=vertices||n!=4+2*std::size_t(edges))return -1;int source=int(v[2]),target=int(v[3]);
    int adj[V][E]={},degree[V]={};for(int e=0;e<edges;++e){auto a=v[4+2*e],b=v[5+2*e];if(a<0||a>=vertices||b<0||b>=vertices)return -1;adj[int(a)][degree[int(a)]++]=int(b);}
    std::uint8_t temp[OUT]={};int path[V]={};bool visited[V]={};std::int64_t count=0;std::size_t at=8;path[0]=source;Search s{adj,degree,visited,path,1,target,&count,temp,&at,false};dfs(s);if(s.overflow)return -2;put_i64(temp,0,count);if(!output||capacity<at)return -2;for(std::size_t i=0;i<at;++i)output[i]=temp[i];return std::int64_t(at);
}
