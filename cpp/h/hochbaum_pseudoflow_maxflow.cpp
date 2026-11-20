#include <cstddef>
#include <cstdint>

#define PF_N 8
#define PF_K 6
#define PF_M 24
#define PF_ITERATIONS 512

static int pf_build_state(int k, const int root_edge[PF_K], const int tree_edges[PF_N], int tree_count,
                          const int edge_u[PF_M], const int edge_v[PF_M], int parent[PF_N + 1],
                          int parent_edge[PF_N + 1], int branch_root[PF_K]) {
    int root = k, adjacency[PF_N + 1][PF_N + 1];
    for (int i=0; i<=k; ++i) for (int j=0; j<=k; ++j) adjacency[i][j]=-2;
    for (int v=0; v<k; ++v) if (root_edge[v]) { adjacency[root][v]=-1; adjacency[v][root]=-1; }
    for (int i=0; i<tree_count; ++i) {
        int e=tree_edges[i], u=edge_u[e], v=edge_v[e]; adjacency[u][v]=e; adjacency[v][u]=e;
    }
    for (int i=0; i<=k; ++i) { parent[i]=-2; parent_edge[i]=-2; }
    for (int i=0; i<k; ++i) branch_root[i]=-1;
    int queue[PF_N+1], head=0, tail=0; parent[root]=-1; queue[tail++]=root;
    while (head<tail) {
        int u=queue[head++];
        for (int v=0; v<=k; ++v) if (adjacency[u][v]!=-2 && parent[v]==-2) {
            parent[v]=u; parent_edge[v]=adjacency[u][v]; branch_root[v]=(u==root ? v : branch_root[u]); queue[tail++]=v;
        }
    }
    return tail==k+1;
}

static void pf_balance(int k, int edge_count, const int64_t weight[PF_K], const int edge_u[PF_M],
                       const int edge_v[PF_M], const int64_t flow[PF_M], int64_t result[PF_K]) {
    for (int v=0; v<k; ++v) result[v]=weight[v];
    for (int e=0; e<edge_count; ++e) { result[edge_u[e]]-=flow[e]; result[edge_v[e]]+=flow[e]; }
}

static int pf_in_tree(const int tree_edges[PF_N], int tree_count, int edge) {
    for (int i=0; i<tree_count; ++i) if (tree_edges[i]==edge) return 1;
    return 0;
}

static void pf_remove_tree_edge(int tree_edges[PF_N], int *tree_count, int edge) {
    for (int i=0; i<*tree_count; ++i) if (tree_edges[i]==edge) {
        for (int j=i; j+1<*tree_count; ++j) tree_edges[j]=tree_edges[j+1];
        --*tree_count; return;
    }
}

extern "C" std::int64_t hochbaum_pseudoflow_maxflow(const std::int64_t *input, std::size_t length) {
    if (!input || length<4 || length>77) return -1;
    int64_t nv=input[0], mv=input[1], sr=input[2], tr=input[3];
    if (nv<2 || nv>PF_N || mv<0 || mv>PF_M || sr<1 || sr>nv || tr<1 || tr>nv || sr==tr) return -1;
    int n=(int)nv, m=(int)mv, source=(int)sr-1, sink=(int)tr-1;
    if (length!=(size_t)(4+3*m)) return -1;
    int local[PF_N], k=0;
    for (int v=0; v<n; ++v) { local[v]=-1; if (v!=source && v!=sink) local[v]=k++; }
    int64_t source_cap[PF_K]={0}, sink_cap[PF_K]={0}, direct_cap=0;
    int edge_u[PF_M]={0}, edge_v[PF_M]={0}, edge_count=0;
    int64_t capacity[PF_M]={0}, flow[PF_M]={0};
    for (int i=0; i<m; ++i) {
        int64_t ur=input[4+3*i], vr=input[5+3*i], cap=input[6+3*i];
        if (ur<1 || ur>nv || vr<1 || vr>nv || ur==vr || cap<0 || cap>100) return -1;
        int u=(int)ur-1, v=(int)vr-1;
        if (u==source) { if (v==sink) direct_cap+=cap; else source_cap[local[v]]+=cap; }
        else if (v==sink) sink_cap[local[u]]+=cap;
        else if (v==source || u==sink) return -1;
        else { edge_u[edge_count]=local[u]; edge_v[edge_count]=local[v]; capacity[edge_count]=cap; ++edge_count; }
    }
    int64_t weight[PF_K]={0}, balance[PF_K]={0}, label[PF_K]={0}, ticket[PF_K]={0}, next_ticket=0;
    int root_edge[PF_K]={0}, tree_edges[PF_N]={0}, tree_count=0;
    for (int v=0; v<k; ++v) { weight[v]=source_cap[v]-sink_cap[v]; root_edge[v]=1; label[v]=1; ticket[v]=next_ticket++; }
    int parent[PF_N+1], parent_edge[PF_N+1], branch_root[PF_K];
    for (int iteration=0; iteration<PF_ITERATIONS; ++iteration) {
        pf_balance(k,edge_count,weight,edge_u,edge_v,flow,balance);
        if (!pf_build_state(k,root_edge,tree_edges,tree_count,edge_u,edge_v,parent,parent_edge,branch_root)) return -1;
        int active[PF_K]={0}, strong[PF_K]={0}, has_crossing=0;
        int64_t old_label[PF_K]={0};
        for (int r=0; r<k; ++r) { old_label[r]=label[r]; if (root_edge[r] && balance[r]>0) active[r]=1; }
        for (int v=0; v<k; ++v) strong[v]=balance[branch_root[v]]>0;
        for (int e=0; e<edge_count; ++e) {
            if (strong[edge_u[e]] && !strong[edge_v[e]] && capacity[e]-flow[e]>0) has_crossing=1;
            if (strong[edge_v[e]] && !strong[edge_u[e]] && flow[e]>0) has_crossing=1;
        }
        if (!has_crossing) {
            int64_t cut=direct_cap;
            for (int v=0; v<k; ++v) cut+=strong[v] ? sink_cap[v] : source_cap[v];
            for (int e=0; e<edge_count; ++e) if (strong[edge_u[e]] && !strong[edge_v[e]]) cut+=capacity[e];
            return cut>=0 && cut<=2400 ? cut : -1;
        }
        int strong_root=-1;
        for (int r=0; r<k; ++r) if (active[r] &&
            (strong_root<0 || label[r]>label[strong_root] || (label[r]==label[strong_root] && ticket[r]<ticket[strong_root]))) strong_root=r;
        if (strong_root<0) return -1;
        int low=INT32_MAX;
        for (int v=0; v<k; ++v) if (branch_root[v]==strong_root && label[v]<low) low=(int)label[v];
        int tail=-1, head=-1, entering=-1;
        for (int v=0; v<k && entering<0; ++v) if (branch_root[v]==strong_root && label[v]==low) {
            for (int e=0; e<edge_count && entering<0; ++e) {
                if (pf_in_tree(tree_edges,tree_count,e)) continue;
                if (edge_u[e]==v && capacity[e]-flow[e]>0 && branch_root[edge_v[e]]!=strong_root && label[edge_v[e]]==low-1) {
                    tail=v; head=edge_v[e]; entering=e;
                } else if (edge_v[e]==v && flow[e]>0 && branch_root[edge_u[e]]!=strong_root && label[edge_u[e]]==low-1) {
                    tail=v; head=edge_u[e]; entering=e;
                }
            }
        }
        if (entering<0) {
            int relabel=-1;
            for (int v=0; v<k && relabel<0; ++v) if (branch_root[v]==strong_root && label[v]==low) {
                int children_ok=1;
                for (int child=0; child<k; ++child) if (parent[child]==v && label[child]<low+1) children_ok=0;
                if (children_ok) relabel=v;
            }
            if (relabel<0) return -1;
            ++label[relabel];
            if (relabel==strong_root) ticket[strong_root]=next_ticket++;
            continue;
        }

        int target_root=branch_root[head], root=k;
        int strong_nodes[PF_N+1], strong_len=0, cursor=tail;
        while (cursor!=root) { strong_nodes[strong_len]=cursor; ++strong_len; cursor=parent[cursor]; }
        int step_from[2*PF_N+2], step_to[2*PF_N+2], step_edge[2*PF_N+2], steps=0;
        for (int j=strong_len-1; j>=0; --j) {
            int child=strong_nodes[j];
            if (parent[child]!=root) { step_from[steps]=parent[child]; step_to[steps]=child; step_edge[steps++]=parent_edge[child]; }
        }
        step_from[steps]=tail; step_to[steps]=head; step_edge[steps++]=entering;
        cursor=head;
        while (cursor!=target_root) { step_from[steps]=cursor; step_to[steps]=parent[cursor]; step_edge[steps++]=parent_edge[cursor]; cursor=parent[cursor]; }
        root_edge[strong_root]=0; tree_edges[tree_count++]=entering;
        for (int j=0; j<strong_len; ++j) if (strong_nodes[j]!=root) label[strong_nodes[j]]=label[head]+1;
        int64_t carry=balance[strong_root];
        for (int j=0; j<steps; ++j) {
            int e=step_edge[j], u=edge_u[e], v=edge_v[e];
            int64_t residual=(step_from[j]==u && step_to[j]==v) ? capacity[e]-flow[e] : flow[e];
            int64_t pushed=carry<residual ? carry : residual;
            if (step_from[j]==u && step_to[j]==v) flow[e]+=pushed; else flow[e]-=pushed;
            if (residual<carry) { pf_remove_tree_edge(tree_edges,&tree_count,e); root_edge[step_from[j]]=1; }
            carry=pushed;
            if (carry==0) break;
        }
        pf_balance(k,edge_count,weight,edge_u,edge_v,flow,balance);
        if (!pf_build_state(k,root_edge,tree_edges,tree_count,edge_u,edge_v,parent,parent_edge,branch_root)) return -1;
        for (int r=0; r<k; ++r) if (root_edge[r] && balance[r]>0 && (!active[r] || label[r]!=old_label[r])) ticket[r]=next_ticket++;
    }
    return -1;
}
