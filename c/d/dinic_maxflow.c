/* Dinic maximum flow with BFS level graphs and blocking-flow DFS. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_EDGES 64
#define MAX_CAPACITY 100
#define INF_FLOW 6401

static int dfs(int u, int sink, int pushed, int64_t residual[MAX_VERTICES][MAX_VERTICES],
               int level[MAX_VERTICES], int next[MAX_VERTICES], int n)
{
    if (u == sink) return pushed;
    while (next[u] < n) {
        int v = next[u];
        if (level[v] == level[u] + 1 && residual[u][v] > 0) {
            int64_t bound = residual[u][v] < pushed ? residual[u][v] : pushed;
            int sent = dfs(v, sink, (int)bound, residual, level, next, n);
            if (sent > 0) { residual[u][v] -= sent; residual[v][u] += sent; return sent; }
        }
        ++next[u];
    }
    return 0;
}

int64_t dinic_maxflow(const int64_t *input, size_t length)
{
    if (!input || length < 4) return -1;
    int64_t nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if(nv<2||nv>MAX_VERTICES||mv<0||mv>MAX_EDGES||sv<1||sv>nv||tv<1||tv>nv||sv==tv)return -1;
    int n=(int)nv,m=(int)mv,s=(int)sv-1,t=(int)tv-1;
    if(length!=(size_t)(4+3*m))return -1;
    int64_t residual[MAX_VERTICES][MAX_VERTICES]={{0}};
    for(int i=0;i<m;i++){
        int64_t uv=input[4+3*i],vv=input[5+3*i],c=input[6+3*i];
        if(uv<1||uv>nv||vv<1||vv>nv||uv==vv||c<0||c>MAX_CAPACITY)return -1;
        residual[uv-1][vv-1]+=c;
    }
    int64_t flow=0;
    for(;;){
        int level[MAX_VERTICES],queue[MAX_VERTICES],head=0,tail=0;
        for(int i=0;i<n;i++)level[i]=-1;
        level[s]=0;queue[tail++]=s;
        while(head<tail){int u=queue[head++];for(int v=0;v<n;v++)if(residual[u][v]>0&&level[v]<0){level[v]=level[u]+1;queue[tail++]=v;}}
        if(level[t]<0)break;
        int next[MAX_VERTICES]={0};
        for(;;){int pushed=dfs(s,t,INF_FLOW,residual,level,next,n);if(!pushed)break;flow+=pushed;}
    }
    return flow;
}
