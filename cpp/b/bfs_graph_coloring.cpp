#include <cstddef>
#include <cstdint>

constexpr int MAX_VERTICES=64, MAX_EDGES=MAX_VERTICES*(MAX_VERTICES-1)/2, MAX_OUTPUT_VALUES=MAX_VERTICES+2;
static void put_i64(std::uint8_t*out,std::size_t offset,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[offset+b]=static_cast<std::uint8_t>(bits>>(8*b));}
extern "C" std::int64_t bfs_graph_coloring(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept{
    if(!input||length<2)return -1;auto nv=input[0],mv=input[1];if(nv<0||nv>MAX_VERTICES||mv<0||mv>MAX_EDGES||length!=2+2*static_cast<std::size_t>(mv))return -1;
    int n=static_cast<int>(nv),m=static_cast<int>(mv);bool adj[MAX_VERTICES*MAX_VERTICES]{};int degree[MAX_VERTICES]{};
    for(int e=0;e<m;++e){auto uv=input[2+2*e],vv=input[3+2*e];if(uv<0||uv>=n||vv<0||vv>=n||uv==vv)return -1;int u=static_cast<int>(uv),v=static_cast<int>(vv);auto a=u*MAX_VERTICES+v,b=v*MAX_VERTICES+u;if(adj[a])return -1;adj[a]=adj[b]=true;++degree[u];++degree[v];}
    bool visited[MAX_VERTICES]{};int queue[MAX_VERTICES];
    for(int start=0;start<n;++start){if(visited[start])continue;int head=0,tail=0,high=0;visited[start]=true;queue[tail++]=start;while(head<tail){int v=queue[head++];if(degree[v]>1)++high;for(int nb=0;nb<n;++nb)if(adj[v*MAX_VERTICES+nb]&&!visited[nb]){visited[nb]=true;queue[tail++]=nb;}}if(high>1)return -1;}
    std::int64_t colors[MAX_VERTICES];for(int i=0;i<n;++i)colors[i]=1;for(bool &v:visited)v=false;
    for(int start=0;start<n;++start){if(visited[start])continue;int head=0,tail=0;visited[start]=true;queue[tail++]=start;while(head<tail){int front=queue[head++];for(int nb=0;nb<n;++nb){if(!adj[front*MAX_VERTICES+nb])continue;if(colors[nb]==colors[front])++colors[nb];if(!visited[nb]){visited[nb]=true;queue[tail++]=nb;}}}}
    std::int64_t used_colors=0,packed[MAX_OUTPUT_VALUES]{};packed[0]=n;for(int i=0;i<n;++i){packed[i+1]=colors[i];if(colors[i]>used_colors)used_colors=colors[i];}packed[n+1]=used_colors;std::size_t used=static_cast<std::size_t>(n)+2,required=used*8;if(!output||capacity<required)return -2;for(std::size_t i=0;i<used;++i)put_i64(output,8*i,packed[i]);return static_cast<std::int64_t>(required);
}
