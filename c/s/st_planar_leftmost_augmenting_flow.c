#include <stddef.h>
#include <stdint.h>

#define MAX_N 6
#define MAX_M 10
#define MAX_INPUT 60

typedef struct { int n,m,s,t; int u[MAX_M],v[MAX_M],cap[MAX_M]; int degree[MAX_N],rot[MAX_N][MAX_N]; } Graph;

static int parse_graph(const int64_t *a,size_t len,Graph *g){
    if(!a||len<4||len>MAX_INPUT)return 0;
    int64_t n0=a[0],m0=a[1],s0=a[2],t0=a[3];
    if(n0<2||n0>MAX_N||m0<1||m0>MAX_M||s0<0||s0>=n0||t0<0||t0>=n0||s0==t0)return 0;
    g->n=(int)n0;g->m=(int)m0;g->s=(int)s0;g->t=(int)t0;
    if(len<(size_t)(4+3*g->m))return 0;
    int seen_pair[MAX_N][MAX_N]={{0}};
    size_t at=4;
    for(int e=0;e<g->m;e++){
        int64_t u=a[at++],v=a[at++],c=a[at++];
        if(u<0||u>=g->n||v<0||v>=g->n||u==v||c<0||c>5)return 0;
        if(seen_pair[u][v]||seen_pair[v][u])return 0;
        seen_pair[u][v]=seen_pair[v][u]=1;g->u[e]=(int)u;g->v[e]=(int)v;g->cap[e]=(int)c;
    }
    int occurrence[MAX_M][2]={{0}};int rot_seen[MAX_N][MAX_M]={{0}};
    for(int x=0;x<g->n;x++){
        if(at>=len)return 0;int64_t d=a[at++];if(d<0||d>g->n-1||at+(size_t)d>len)return 0;
        g->degree[x]=(int)d;
        for(int j=0;j<g->degree[x];j++){
            int64_t e0=a[at++];if(e0<0||e0>=g->m)return 0;int e=(int)e0;
            if(rot_seen[x][e])return 0;rot_seen[x][e]=1;g->rot[x][j]=e;
            if(g->u[e]==x)occurrence[e][0]++;else if(g->v[e]==x)occurrence[e][1]++;else return 0;
        }
    }
    if(at!=len)return 0;
    for(int e=0;e<g->m;e++)if(occurrence[e][0]!=1||occurrence[e][1]!=1)return 0;
    int seen[MAX_N]={0},queue[MAX_N],head=0,tail=0;seen[g->s]=1;queue[tail++]=g->s;
    while(head<tail){int x=queue[head++];for(int e=0;e<g->m;e++){int y=g->u[e]==x?g->v[e]:(g->v[e]==x?g->u[e]:-1);if(y>=0&&!seen[y]){seen[y]=1;queue[tail++]=y;}}}
    for(int x=0;x<g->n;x++)if(!seen[x])return 0;
    return 1;
}
static int residual(const Graph *g,const int flow[MAX_M],int x,int e){return g->u[e]==x?g->cap[e]-flow[e]:flow[e];}
static int neighbor(const Graph *g,int x,int e){return g->u[e]==x?g->v[e]:g->u[e];}
int64_t st_planar_leftmost_augmenting_flow(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    Graph g;if(!parse_graph(input,length,&g))return -1;
    int flow[MAX_M]={0},total=0;
    for(;;){
        int seen[MAX_N]={0},parent[MAX_N],parent_edge[MAX_N],parent_dir[MAX_N],next[MAX_N]={0},stack[MAX_N],top=0;
        for(int x=0;x<g.n;x++)parent[x]=parent_edge[x]=-1;
        seen[g.s]=1;stack[top++]=g.s;
        while(top>0&&!seen[g.t]){
            int x=stack[top-1];
            if(next[x]>=g.degree[x]){top--;continue;}
            int e=g.rot[x][next[x]++],y=neighbor(&g,x,e),r=residual(&g,flow,x,e);
            if(r>0&&!seen[y]){seen[y]=1;parent[y]=x;parent_edge[y]=e;parent_dir[y]=(g.u[e]==x?1:-1);stack[top++]=y;}
        }
        if(!seen[g.t])break;
        int delta=1000000;
        for(int y=g.t;y!=g.s;y=parent[y]){int e=parent_edge[y],r=residual(&g,flow,parent[y],e);if(r<delta)delta=r;}
        for(int y=g.t;y!=g.s;y=parent[y])flow[parent_edge[y]]+=parent_dir[y]*delta;
        total+=delta;
    }
    if(!output||capacity<8)return -2;
    uint64_t bits=(uint64_t)(int64_t)total;for(int b=0;b<8;b++)output[b]=(uint8_t)(bits>>(8*b));return 8;
}
