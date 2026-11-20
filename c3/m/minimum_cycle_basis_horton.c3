module minimum_cycle_basis_horton;

const int MIN_N=3, MAX_N=8, MAX_M=12, MAX_LEN=39, MAX_CANDIDATES=96;
struct Edge { int u; int v; long weight; }

fn long cycle_weight(ulong mask, Edge* edges, int m) {
    long total=0;
    for(int e=0;e<m;e++) if((mask>>e)&1ul) total+=edges[e].weight;
    return total;
}

fn long horton_weight(int n,int m,Edge* edges) {
    ulong candidates[MAX_CANDIDATES];long costs[MAX_CANDIDATES];int candidate_count=0;
    for(int root=0;root<n;root++) {
        long distance[MAX_N];int parent[MAX_N],parent_edge[MAX_N];bool settled[MAX_N]={};bool tree_edge[MAX_M]={};ulong path_mask[MAX_N]={};
        for(int v=0;v<n;v++){distance[v]=0x3fffffffffffffff;parent[v]=-1;parent_edge[v]=-1;}distance[root]=0;
        long tie_scale=(m+1)*(1l<<m);
        for(int step=0;step<n;step++) {
            int vertex=-1;
            for(int v=0;v<n;v++) if(!settled[v]&&distance[v]!=0x3fffffffffffffff&&(vertex<0||distance[v]<distance[vertex]||(distance[v]==distance[vertex]&&v<vertex))) vertex=v;
            if(vertex<0) break;settled[vertex]=true;
            for(int e=0;e<m;e++) {
                int neighbor=edges[e].u==vertex?edges[e].v:edges[e].v==vertex?edges[e].u:-1;
                if(neighbor<0||settled[neighbor]) continue;
                long candidate=distance[vertex]+edges[e].weight*tie_scale+(1l<<e);
                if(candidate<distance[neighbor]) {
                    distance[neighbor]=candidate;parent[neighbor]=vertex;parent_edge[neighbor]=e;
                }
            }
        }
        for(int v=0;v<n;v++) if(v!=root) {
            int cursor=v,steps=0;
            while(cursor!=root&&steps<n) {int pe=parent_edge[cursor];if(pe<0)return -1;tree_edge[pe]=true;path_mask[v]|=1ul<<pe;cursor=parent[cursor];steps++;}
            if(cursor!=root)return -1;
        }
        for(int e=0;e<m;e++) if(!tree_edge[e]) {
            ulong cycle=path_mask[edges[e].u]^path_mask[edges[e].v]^(1ul<<e);if(cycle==0)continue;bool duplicate=false;
            for(int i=0;i<candidate_count;i++)if(candidates[i]==cycle){duplicate=true;break;}
            if(!duplicate&&candidate_count<MAX_CANDIDATES){candidates[candidate_count]=cycle;costs[candidate_count]=cycle_weight(cycle,edges,m);candidate_count++;}
        }
    }
    for(int i=0;i<candidate_count;i++)for(int j=i+1;j<candidate_count;j++)if(costs[j]<costs[i]||(costs[j]==costs[i]&&candidates[j]<candidates[i])){long c=costs[i];costs[i]=costs[j];costs[j]=c;ulong x=candidates[i];candidates[i]=candidates[j];candidates[j]=x;}
    int dimension=m-n+1,rank=0;long total=0;ulong basis[MAX_M]={};
    for(int i=0;i<candidate_count&&rank<dimension;i++){ulong residual=candidates[i];for(int bit=m-1;bit>=0;bit--)if((residual>>bit)&1ul){if(basis[bit]!=0)residual^=basis[bit];else{basis[bit]=residual;rank++;total+=costs[i];break;}}}
    return rank==dimension?total:-1;
}

fn long minimum_cycle_basis_horton(long* input,usz length)
    @export("minimum_cycle_basis_horton") {
    if(input==null||length<2||length>MAX_LEN)return -1;
    long nv=input[0],mv=input[1];if(nv<MIN_N||nv>MAX_N)return -1;int n=(int)nv;
    if(mv<n-1||mv>MAX_M||mv>n*(n-1)/2)return -1;int m=(int)mv;if(length!=(usz)(2+3*m))return -1;
    Edge edges[MAX_M];int edge_id[MAX_N][MAX_N];for(int u=0;u<n;u++)for(int v=0;v<n;v++)edge_id[u][v]=-1;
    int previous_u=-1,previous_v=-1;
    for(int e=0;e<m;e++) {
        long ru=input[2+3*e],rv=input[3+3*e],weight=input[4+3*e];
        if(ru<0||rv<0||ru>=nv||rv>=nv||ru>=rv||weight<1||weight>9)return -1;
        int u=(int)ru,v=(int)rv;if(e>0&&(u<previous_u||(u==previous_u&&v<=previous_v)))return -1;
        previous_u=u;previous_v=v;edges[e]=Edge{u,v,weight};edge_id[u][v]=e;edge_id[v][u]=e;
    }
    bool seen[MAX_N]={};int queue[MAX_N],head=0,tail=0;seen[0]=true;queue[tail++]=0;
    while(head<tail){int x=queue[head++];for(int v=0;v<n;v++)if(edge_id[x][v]>=0&&!seen[v]){seen[v]=true;queue[tail++]=v;}}
    for(int v=0;v<n;v++)if(!seen[v])return -1;
    return horton_weight(n,m,&edges[0]);
}
