module hochbaum_pseudoflow_maxflow;

const int PF_N=8, PF_K=6, PF_M=24, PF_ITERATIONS=512;

fn bool pf_build_state(int k, int* root_edge, int* tree_edges, int tree_count,
                       int* edge_u, int* edge_v, int* parent, int* parent_edge, int* branch_root) {
    int root=k;
    int[81] adjacency=zeroed;
    for (int i=0; i<81; i++) adjacency[i]=-2;
    for (int v=0; v<k; v++) if (root_edge[v]) { adjacency[root*9+v]=-1; adjacency[v*9+root]=-1; }
    for (int i=0; i<tree_count; i++) { int e=tree_edges[i],u=edge_u[e],v=edge_v[e]; adjacency[u*9+v]=e; adjacency[v*9+u]=e; }
    for (int i=0; i<9; i++) { parent[i]=-2; parent_edge[i]=-2; }
    for (int i=0; i<k; i++) branch_root[i]=-1;
    int[9] queue=zeroed; int head=0,tail=1; parent[root]=-1; queue[0]=root;
    while (head<tail) {
        int u=queue[head++];
        for (int v=0; v<=k; v++) if (adjacency[u*9+v]!=-2 && parent[v]==-2) {
            parent[v]=u; parent_edge[v]=adjacency[u*9+v]; branch_root[v]=(u==root ? v : branch_root[u]); queue[tail++]=v;
        }
    }
    return tail==k+1;
}

fn void pf_balance(int k, int edge_count, long* weight, int* edge_u, int* edge_v, long* flow, long* result) {
    for (int v=0; v<k; v++) result[v]=weight[v];
    for (int e=0; e<edge_count; e++) { result[edge_u[e]]-=flow[e]; result[edge_v[e]]+=flow[e]; }
}

fn bool pf_in_tree(int* tree_edges, int tree_count, int edge) {
    for (int i=0; i<tree_count; i++) if (tree_edges[i]==edge) return true;
    return false;
}

fn bool pf_remove_tree_edge(int* tree_edges, int* tree_count, int edge) {
    for (int i=0; i<*tree_count; i++) if (tree_edges[i]==edge) {
        for (int j=i; j+1<*tree_count; j++) tree_edges[j]=tree_edges[j+1];
        *tree_count=*tree_count-1; return true;
    }
    return false;
}

fn long hochbaum_pseudoflow_maxflow(long* input, usz length) @export("hochbaum_pseudoflow_maxflow") {
    if (input==null || length<4 || length>77) return -1;
    long nv=input[0],mv=input[1],sr=input[2],tr=input[3];
    if (nv<2 || nv>PF_N || mv<0 || mv>PF_M || sr<1 || sr>nv || tr<1 || tr>nv || sr==tr) return -1;
    int n=(int)nv,m=(int)mv,source=(int)sr-1,sink=(int)tr-1;
    if (length!=(usz)(4+3*m)) return -1;
    int[8] local=zeroed; for (int v=0; v<n; v++) local[v]=-1;
    int k=0; for (int v=0; v<n; v++) if (v!=source && v!=sink) local[v]=k++;
    long[6] source_cap=zeroed,sink_cap=zeroed; long direct_cap=0;
    int[24] edge_u=zeroed,edge_v=zeroed; long[24] capacity=zeroed,flow=zeroed; int edge_count=0;
    for (int i=0; i<m; i++) {
        long ur=input[4+3*i],vr=input[5+3*i],cap=input[6+3*i];
        if (ur<1 || ur>nv || vr<1 || vr>nv || ur==vr || cap<0 || cap>100) return -1;
        int u=(int)ur-1,v=(int)vr-1;
        if (u==source) { if (v==sink) direct_cap+=cap; else source_cap[local[v]]+=cap; }
        else if (v==sink) sink_cap[local[u]]+=cap;
        else if (v==source || u==sink) return -1;
        else { edge_u[edge_count]=local[u];edge_v[edge_count]=local[v];capacity[edge_count]=cap;edge_count++; }
    }
    long[6] weight=zeroed,balance=zeroed,label=zeroed,ticket=zeroed; int[6] root_edge=zeroed;
    int[8] tree_edges=zeroed; int tree_count=0; long next_ticket=0;
    for (int v=0;v<k;v++) { weight[v]=source_cap[v]-sink_cap[v];root_edge[v]=1;label[v]=1;ticket[v]=next_ticket++; }
    int[9] parent=zeroed,parent_edge=zeroed; int[6] branch_root=zeroed;
    for (int iteration=0;iteration<PF_ITERATIONS;iteration++) {
        pf_balance(k,edge_count,&weight[0],&edge_u[0],&edge_v[0],&flow[0],&balance[0]);
        if (!pf_build_state(k,&root_edge[0],&tree_edges[0],tree_count,&edge_u[0],&edge_v[0],&parent[0],&parent_edge[0],&branch_root[0])) return -1;
        int[6] active=zeroed,strong=zeroed; long[6] old_label=zeroed;
        for (int r=0;r<k;r++) { old_label[r]=label[r]; if (root_edge[r]!=0 && balance[r]>0) active[r]=1; }
        for (int v=0;v<k;v++) strong[v]=balance[branch_root[v]]>0 ? 1 : 0;
        bool crossing=false;
        for (int e=0;e<edge_count;e++) {
            if (strong[edge_u[e]]!=0 && strong[edge_v[e]]==0 && capacity[e]-flow[e]>0) crossing=true;
            if (strong[edge_v[e]]!=0 && strong[edge_u[e]]==0 && flow[e]>0) crossing=true;
        }
        if (!crossing) {
            long cut=direct_cap;
            for (int v=0;v<k;v++) cut+=strong[v]!=0 ? sink_cap[v] : source_cap[v];
            for (int e=0;e<edge_count;e++) if (strong[edge_u[e]]!=0 && strong[edge_v[e]]==0) cut+=capacity[e];
            return cut>=0 && cut<=2400 ? cut : -1;
        }
        int sr_root=-1;
        for (int r=0;r<k;r++) if (active[r]!=0 && (sr_root<0 || label[r]>label[sr_root] || (label[r]==label[sr_root] && ticket[r]<ticket[sr_root]))) sr_root=r;
        if (sr_root<0) return -1;
        long low=1000; for (int v=0;v<k;v++) if (branch_root[v]==sr_root && label[v]<low) low=label[v];
        int tail=-1,head_node=-1,entering=-1;
        for (int v=0;v<k && entering<0;v++) if (branch_root[v]==sr_root && label[v]==low) {
            for (int e=0;e<edge_count && entering<0;e++) {
                if (pf_in_tree(&tree_edges[0],tree_count,e)) continue;
                if (edge_u[e]==v && capacity[e]-flow[e]>0 && branch_root[edge_v[e]]!=sr_root && label[edge_v[e]]==low-1) { tail=v;head_node=edge_v[e];entering=e; }
                else if (edge_v[e]==v && flow[e]>0 && branch_root[edge_u[e]]!=sr_root && label[edge_u[e]]==low-1) { tail=v;head_node=edge_u[e];entering=e; }
            }
        }
        if (entering<0) {
            int relabel=-1;
            for (int v=0;v<k && relabel<0;v++) if (branch_root[v]==sr_root && label[v]==low) {
                int ok=1;for(int child=0;child<k;child++)if(parent[child]==v && label[child]<low+1)ok=0;
                if(ok)relabel=v;
            }
            if(relabel<0)return -1;label[relabel]++;if(relabel==sr_root)ticket[sr_root]=next_ticket++;continue;
        }
        int target_root=branch_root[head_node],root=k;
        int[9] chain=zeroed;int chain_len=0,cursor=tail;
        while(cursor!=root){chain[chain_len++]=cursor;cursor=parent[cursor];}
        int[18] step_from=zeroed,step_to=zeroed,step_edge=zeroed;int steps=0;
        for(int j=chain_len-1;j>=0;j--){int child=chain[j];if(parent[child]!=root){step_from[steps]=parent[child];step_to[steps]=child;step_edge[steps++]=parent_edge[child];}}
        step_from[steps]=tail;step_to[steps]=head_node;step_edge[steps++]=entering;
        cursor=head_node;while(cursor!=target_root){step_from[steps]=cursor;step_to[steps]=parent[cursor];step_edge[steps++]=parent_edge[cursor];cursor=parent[cursor];}
        root_edge[sr_root]=0;tree_edges[tree_count++]=entering;
        for(int j=0;j<chain_len;j++)label[chain[j]]=label[head_node]+1;
        long carry=balance[sr_root];
        for(int j=0;j<steps;j++){
            int e=step_edge[j],u=edge_u[e],v=edge_v[e];long residual=step_from[j]==u&&step_to[j]==v?capacity[e]-flow[e]:flow[e];
            long pushed=carry<residual?carry:residual;
            if(step_from[j]==u&&step_to[j]==v)flow[e]+=pushed;else flow[e]-=pushed;
            if(residual<carry){if(!pf_remove_tree_edge(&tree_edges[0],&tree_count,e))return -1;root_edge[step_from[j]]=1;}
            carry=pushed;if(carry==0)break;
        }
        pf_balance(k,edge_count,&weight[0],&edge_u[0],&edge_v[0],&flow[0],&balance[0]);
        if(!pf_build_state(k,&root_edge[0],&tree_edges[0],tree_count,&edge_u[0],&edge_v[0],&parent[0],&parent_edge[0],&branch_root[0]))return -1;
        for(int r=0;r<k;r++)if(root_edge[r]!=0&&balance[r]>0&&(active[r]==0||label[r]!=old_label[r]))ticket[r]=next_ticket++;
    }
    return -1;
}
