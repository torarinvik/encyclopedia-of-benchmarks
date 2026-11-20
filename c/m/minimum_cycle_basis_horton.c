#include <stddef.h>
#include <stdint.h>

enum { MIN_N=3, MAX_N=8, MAX_M=12, MAX_LEN=39, MAX_CANDIDATES=96 };
typedef struct { int u, v; int64_t weight; } Edge;

static int64_t cycle_weight(uint64_t mask, const Edge edges[MAX_M], int m) {
    int64_t total=0;
    for(int e=0;e<m;e++) if((mask>>e)&1u) total+=edges[e].weight;
    return total;
}

static int64_t horton_weight(int n,int m,const Edge edges[MAX_M]) {
    uint64_t candidates[MAX_CANDIDATES];
    int64_t costs[MAX_CANDIDATES];
    int candidate_count=0;
    for(int root=0;root<n;root++) {
        int64_t distance[MAX_N];
        int parent[MAX_N],parent_edge[MAX_N],settled[MAX_N]={0},tree_edge[MAX_M]={0};
        uint64_t path_mask[MAX_N]={0};
        for(int v=0;v<n;v++){distance[v]=INT64_MAX;parent[v]=-1;parent_edge[v]=-1;}
        distance[root]=0;
        int64_t tie_scale=(int64_t)(m+1)*(INT64_C(1)<<m);
        for(int step=0;step<n;step++) {
            int vertex=-1;
            for(int v=0;v<n;v++) if(!settled[v] && distance[v]!=INT64_MAX &&
                (vertex<0 || distance[v]<distance[vertex] || (distance[v]==distance[vertex]&&v<vertex))) vertex=v;
            if(vertex<0) break;
            settled[vertex]=1;
            for(int e=0;e<m;e++) {
                int neighbor=edges[e].u==vertex?edges[e].v:edges[e].v==vertex?edges[e].u:-1;
                if(neighbor<0||settled[neighbor]) continue;
                int64_t candidate=distance[vertex]+edges[e].weight*tie_scale+(INT64_C(1)<<e);
                if(candidate<distance[neighbor]) {
                    distance[neighbor]=candidate;parent[neighbor]=vertex;parent_edge[neighbor]=e;
                }
            }
        }
        for(int v=0;v<n;v++) if(v!=root) {
            int cursor=v,steps=0;
            while(cursor!=root && steps<n) {
                int pe=parent_edge[cursor];
                if(pe<0) return -1;
                tree_edge[pe]=1;path_mask[v]|=UINT64_C(1)<<pe;
                cursor=parent[cursor];steps++;
            }
            if(cursor!=root) return -1;
        }
        for(int e=0;e<m;e++) if(!tree_edge[e]) {
            uint64_t cycle=path_mask[edges[e].u]^path_mask[edges[e].v]^(UINT64_C(1)<<e);
            if(!cycle) continue;
            int duplicate=0;
            for(int i=0;i<candidate_count;i++) if(candidates[i]==cycle){duplicate=1;break;}
            if(!duplicate && candidate_count<MAX_CANDIDATES) {
                candidates[candidate_count]=cycle;costs[candidate_count]=cycle_weight(cycle,edges,m);candidate_count++;
            }
        }
    }
    for(int i=0;i<candidate_count;i++) for(int j=i+1;j<candidate_count;j++)
        if(costs[j]<costs[i] || (costs[j]==costs[i]&&candidates[j]<candidates[i])) {
            int64_t c=costs[i];costs[i]=costs[j];costs[j]=c;
            uint64_t x=candidates[i];candidates[i]=candidates[j];candidates[j]=x;
        }
    int dimension=m-n+1,rank=0;int64_t total=0;uint64_t basis[MAX_M]={0};
    for(int i=0;i<candidate_count && rank<dimension;i++) {
        uint64_t residual=candidates[i];
        for(int bit=m-1;bit>=0;bit--) if((residual>>bit)&1u) {
            if(basis[bit]) residual^=basis[bit];
            else {basis[bit]=residual;rank++;total+=costs[i];break;}
        }
    }
    return rank==dimension?total:-1;
}

int64_t minimum_cycle_basis_horton(const int64_t *input,size_t length) {
    if(input==NULL||length<2||length>MAX_LEN) return -1;
    if(input[0]<MIN_N||input[0]>MAX_N) return -1;
    int n=(int)input[0];
    if(input[1]<n-1||input[1]>MAX_M||input[1]>n*(n-1)/2) return -1;
    int m=(int)input[1];
    if(length!=(size_t)(2+3*m)) return -1;
    Edge edges[MAX_M];int edge_id[MAX_N][MAX_N];
    for(int u=0;u<n;u++)for(int v=0;v<n;v++)edge_id[u][v]=-1;
    int previous_u=-1,previous_v=-1;
    for(int e=0;e<m;e++) {
        int64_t ru=input[2+3*e],rv=input[3+3*e],weight=input[4+3*e];
        if(ru<0||rv<0||ru>=n||rv>=n||ru>=rv||weight<1||weight>9) return -1;
        int u=(int)ru,v=(int)rv;
        if(e>0 && (u<previous_u || (u==previous_u&&v<=previous_v))) return -1;
        previous_u=u;previous_v=v;edges[e]=(Edge){u,v,weight};edge_id[u][v]=edge_id[v][u]=e;
    }
    int seen[MAX_N]={0},queue[MAX_N],head=0,tail=0;seen[0]=1;queue[tail++]=0;
    while(head<tail){int x=queue[head++];for(int v=0;v<n;v++)if(edge_id[x][v]>=0&&!seen[v]){seen[v]=1;queue[tail++]=v;}}
    for(int v=0;v<n;v++)if(!seen[v])return -1;
    return horton_weight(n,m,edges);
}
