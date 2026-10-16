#include <cstddef>
#include <cstdint>

namespace {
constexpr int N=32,M=256,Q=64;
struct Graph{int n,m,q,adj[N][M]{},degree[N]{},mode[Q]{},start[Q]{},dest[Q]{};};
struct Path{int length=-1,nodes[N]{};};
bool dfs(const Graph&g,int at,int dest,int*path,int depth,int&length,bool*visited){if(visited[at])return false;visited[at]=true;if(at==dest){length=depth;return true;}for(int i=0;i<g.degree[at];++i){int next=g.adj[at][i];path[depth]=next;if(dfs(g,next,dest,path,depth+1,length,visited))return true;}return false;}
Path search(const Graph&g,int mode,int start,int dest){Path out;if(mode==0){int path[N]{},length=-1;bool visited[N]{};if(dfs(g,start,dest,path,0,length,visited)){out.length=length;for(int i=0;i<length;++i)out.nodes[i]=path[i];}return out;}int parent[N],queue[N],head=0,tail=0;for(int&i:parent)i=-1;parent[start]=start;queue[tail++]=start;while(head<tail){int at=queue[head++];if(at==dest)break;for(int i=0;i<g.degree[at];++i){int next=g.adj[at][i];if(parent[next]==-1){parent[next]=at;queue[tail++]=next;}}}if(parent[dest]==-1)return out;int reverse[N],count=0,at=dest;while(at!=start){reverse[count++]=at;at=parent[at];}out.length=count;for(int i=0;i<count;++i)out.nodes[i]=reverse[count-1-i];return out;}
void put(std::uint8_t*out,std::size_t pos,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[pos+b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t graph_swift_directed_paths(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept{
 if(!in||len<3)return -1;auto n=in[0],m=in[1];if(n<1||n>N||m<0||m>M)return -1;auto qp=std::size_t(2+2*m);if(len<qp+1)return -1;auto q=in[qp];if(q<1||q>Q||len!=qp+1+3*std::size_t(q))return -1;
 Graph g{};g.n=int(n);g.m=int(m);g.q=int(q);for(int i=0;i<g.m;++i){auto u=in[2+2*i],v=in[3+2*i];if(u<0||u>=n||v<=u||v>=n)return -1;g.adj[u][g.degree[u]++]=int(v);}
 for(int i=0;i<g.q;++i){auto p=qp+1+3*std::size_t(i);auto mode=in[p],s=in[p+1],d=in[p+2];if(mode<0||mode>1||s<0||s>=n||d<0||d>=n)return -1;g.mode[i]=int(mode);g.start[i]=int(s);g.dest[i]=int(d);}
 Path paths[Q]{};std::size_t words=0;for(int i=0;i<g.q;++i){paths[i]=search(g,g.mode[i],g.start[i],g.dest[i]);words+=1+(paths[i].length>0?std::size_t(paths[i].length):0);}auto required=words*8;if(!out||cap<required)return -2;std::size_t pos=0;for(int i=0;i<g.q;++i){put(out,pos++*8,paths[i].length);for(int j=0;j<paths[i].length;++j)put(out,pos++*8,paths[i].nodes[j]);}return static_cast<std::int64_t>(required);
}
