/* Dinic maximum flow with BFS level graphs and blocking-flow DFS. */
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices=16,max_edges=64,inf_flow=6401;
int dfs(int u,int sink,int pushed,std::int64_t residual[max_vertices][max_vertices],int level[max_vertices],int next[max_vertices],int n){
    if(u==sink)return pushed;
    while(next[u]<n){int v=next[u];if(level[v]==level[u]+1&&residual[u][v]>0){int sent=dfs(v,sink,std::min<std::int64_t>(pushed,residual[u][v]),residual,level,next,n);if(sent>0){residual[u][v]-=sent;residual[v][u]+=sent;return sent;}}++next[u];}
    return 0;
}
}
extern "C" std::int64_t dinic_maxflow(const std::int64_t* input,std::size_t length) noexcept {
    if(!input||length<4)return -1;auto nv=input[0],mv=input[1],sv=input[2],tv=input[3];
    if(nv<2||nv>16||mv<0||mv>64||sv<1||sv>nv||tv<1||tv>nv||sv==tv)return -1;
    int n=static_cast<int>(nv),m=static_cast<int>(mv),s=static_cast<int>(sv-1),t=static_cast<int>(tv-1);if(length!=static_cast<std::size_t>(4+3*m))return -1;
    std::int64_t residual[max_vertices][max_vertices]{};
    for(int i=0;i<m;i++){auto u=input[4+3*i],v=input[5+3*i],c=input[6+3*i];if(u<1||u>nv||v<1||v>nv||u==v||c<0||c>100)return -1;residual[u-1][v-1]+=c;}
    std::int64_t flow=0;
    for(;;){int level[max_vertices],queue[max_vertices],head=0,tail=0;std::fill(level,level+n,-1);level[s]=0;queue[tail++]=s;
        while(head<tail){int u=queue[head++];for(int v=0;v<n;v++)if(residual[u][v]>0&&level[v]<0){level[v]=level[u]+1;queue[tail++]=v;}}
        if(level[t]<0)break;int next[max_vertices]{};for(;;){int pushed=dfs(s,t,inf_flow,residual,level,next,n);if(!pushed)break;flow+=pushed;}
    }return flow;
}
