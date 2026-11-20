#include <cstddef>
#include <cstdint>

namespace {
constexpr int min_n=3,max_n=8,max_m=12,max_len=39,max_candidates=96;
struct Edge { int u,v; std::int64_t weight; };
std::int64_t cycle_weight(std::uint64_t mask,const Edge edges[max_m],int m) {
    std::int64_t total=0;for(int e=0;e<m;e++)if((mask>>e)&1u)total+=edges[e].weight;return total;
}
std::int64_t horton_weight(int n,int m,const Edge edges[max_m]) {
    std::uint64_t candidates[max_candidates]{};std::int64_t costs[max_candidates]{};int candidate_count=0;
    for(int root=0;root<n;root++) {
        std::int64_t distance[max_n];int parent[max_n],parent_edge[max_n];bool settled[max_n]{},tree_edge[max_m]{};std::uint64_t path_mask[max_n]{};
        for(int v=0;v<n;v++){distance[v]=INT64_MAX;parent[v]=parent_edge[v]=-1;}distance[root]=0;
        const std::int64_t tie_scale=static_cast<std::int64_t>(m+1)*(INT64_C(1)<<m);
        for(int step=0;step<n;step++) {
            int vertex=-1;for(int v=0;v<n;v++)if(!settled[v]&&distance[v]!=INT64_MAX&&(vertex<0||distance[v]<distance[vertex]||(distance[v]==distance[vertex]&&v<vertex)))vertex=v;
            if(vertex<0)break;settled[vertex]=true;
            for(int e=0;e<m;e++) {
                int neighbor=edges[e].u==vertex?edges[e].v:edges[e].v==vertex?edges[e].u:-1;if(neighbor<0||settled[neighbor])continue;
                auto candidate=distance[vertex]+edges[e].weight*tie_scale+(INT64_C(1)<<e);
                if(candidate<distance[neighbor]) {
                    distance[neighbor]=candidate;parent[neighbor]=vertex;parent_edge[neighbor]=e;
                }
            }
        }
        for(int v=0;v<n;v++)if(v!=root){int cursor=v,steps=0;while(cursor!=root&&steps<n){int pe=parent_edge[cursor];if(pe<0)return -1;tree_edge[pe]=true;path_mask[v]|=UINT64_C(1)<<pe;cursor=parent[cursor];steps++;}if(cursor!=root)return -1;}
        for(int e=0;e<m;e++)if(!tree_edge[e]) {
            auto cycle=path_mask[edges[e].u]^path_mask[edges[e].v]^(UINT64_C(1)<<e);if(!cycle)continue;bool duplicate=false;
            for(int i=0;i<candidate_count;i++)if(candidates[i]==cycle){duplicate=true;break;}
            if(!duplicate&&candidate_count<max_candidates){candidates[candidate_count]=cycle;costs[candidate_count]=cycle_weight(cycle,edges,m);candidate_count++;}
        }
    }
    for(int i=0;i<candidate_count;i++)for(int j=i+1;j<candidate_count;j++)if(costs[j]<costs[i]||(costs[j]==costs[i]&&candidates[j]<candidates[i])){auto c=costs[i];costs[i]=costs[j];costs[j]=c;auto x=candidates[i];candidates[i]=candidates[j];candidates[j]=x;}
    int dimension=m-n+1,rank=0;std::int64_t total=0;std::uint64_t basis[max_m]{};
    for(int i=0;i<candidate_count&&rank<dimension;i++){auto residual=candidates[i];for(int bit=m-1;bit>=0;bit--)if((residual>>bit)&1u){if(basis[bit])residual^=basis[bit];else{basis[bit]=residual;rank++;total+=costs[i];break;}}}
    return rank==dimension?total:-1;
}
}

extern "C" std::int64_t minimum_cycle_basis_horton(const std::int64_t *input,std::size_t length) {
    if(input==nullptr||length<2||length>max_len)return -1;if(input[0]<min_n||input[0]>max_n)return -1;int n=static_cast<int>(input[0]);
    if(input[1]<n-1||input[1]>max_m||input[1]>n*(n-1)/2)return -1;int m=static_cast<int>(input[1]);if(length!=static_cast<std::size_t>(2+3*m))return -1;
    Edge edges[max_m]{};int edge_id[max_n][max_n];for(int u=0;u<n;u++)for(int v=0;v<n;v++)edge_id[u][v]=-1;int pu=-1,pv=-1;
    for(int e=0;e<m;e++){auto ru=input[2+3*e],rv=input[3+3*e],w=input[4+3*e];if(ru<0||rv<0||ru>=n||rv>=n||ru>=rv||w<1||w>9)return -1;int u=static_cast<int>(ru),v=static_cast<int>(rv);if(e>0&&(u<pu||(u==pu&&v<=pv)))return -1;pu=u;pv=v;edges[e]={u,v,w};edge_id[u][v]=edge_id[v][u]=e;}
    bool seen[max_n]{};int queue[max_n],head=0,tail=0;seen[0]=true;queue[tail++]=0;while(head<tail){int x=queue[head++];for(int v=0;v<n;v++)if(edge_id[x][v]>=0&&!seen[v]){seen[v]=true;queue[tail++]=v;}}for(int v=0;v<n;v++)if(!seen[v])return -1;
    return horton_weight(n,m,edges);
}
