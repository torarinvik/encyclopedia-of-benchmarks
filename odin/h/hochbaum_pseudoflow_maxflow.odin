package hochbaum_pseudoflow_maxflow
import "core:c"

PF_N :: 8
PF_K :: 6
PF_M :: 24
PF_ITERATIONS :: 512

pf_build_state :: proc(k: int, root_edge: ^[PF_K]int, tree_edges: ^[PF_N]int, tree_count: int,
                       edge_u, edge_v: ^[PF_M]int, parent, parent_edge: ^[PF_N+1]int,
                       branch_root: ^[PF_K]int) -> bool {
    root:=k
    adjacency: [81]int = {}
    for i:=0; i<81; i+=1 { adjacency[i]=-2 }
    for v:=0; v<k; v+=1 { if root_edge[v]!=0 { adjacency[root*9+v]=-1; adjacency[v*9+root]=-1 } }
    for i:=0; i<tree_count; i+=1 { e:=tree_edges[i]; u:=edge_u[e]; v:=edge_v[e]; adjacency[u*9+v]=e; adjacency[v*9+u]=e }
    for i:=0; i<PF_N+1; i+=1 { parent[i]=-2; parent_edge[i]=-2 }
    for i:=0; i<k; i+=1 { branch_root[i]=-1 }
    queue: [PF_N+1]int = {}; head:=0; tail:=1; parent[root]=-1; queue[0]=root
    for head<tail {
        u:=queue[head]; head+=1
        for v:=0; v<=k; v+=1 {
            if adjacency[u*9+v]!=-2 && parent[v]==-2 {
                parent[v]=u; parent_edge[v]=adjacency[u*9+v]
                if u==root { branch_root[v]=v } else { branch_root[v]=branch_root[u] }
                queue[tail]=v; tail+=1
            }
        }
    }
    return tail==k+1
}

pf_balance :: proc(k, edge_count: int, weight: ^[PF_K]i64, edge_u, edge_v: ^[PF_M]int,
                   flow: ^[PF_M]i64, balance: ^[PF_K]i64) {
    for v:=0; v<k; v+=1 { balance[v]=weight[v] }
    for e:=0; e<edge_count; e+=1 { balance[edge_u[e]]-=flow[e]; balance[edge_v[e]]+=flow[e] }
}

pf_in_tree :: proc(tree_edges: ^[PF_N]int, tree_count, edge: int) -> bool {
    for i:=0; i<tree_count; i+=1 { if tree_edges[i]==edge { return true } }
    return false
}

pf_remove_tree_edge :: proc(tree_edges: ^[PF_N]int, tree_count: ^int, edge: int) -> bool {
    for i:=0; i<tree_count^; i+=1 {
        if tree_edges[i]==edge {
            for j:=i; j+1<tree_count^; j+=1 { tree_edges[j]=tree_edges[j+1] }
            tree_count^-=1
            return true
        }
    }
    return false
}

@(export)
hochbaum_pseudoflow_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<4 || length>77 do return -1
    nv,mv,sr,tr:=input[0],input[1],input[2],input[3]
    if nv<2 || nv>8 || mv<0 || mv>24 || sr<1 || sr>nv || tr<1 || tr>nv || sr==tr do return -1
    n,m,source,sink:=int(nv),int(mv),int(sr-1),int(tr-1)
    if length!=c.size_t(4+3*m) do return -1
    local: [8]int = {}
    for v:=0; v<n; v+=1 { local[v]=-1 }
    k:=0
    for v:=0; v<n; v+=1 { if v!=source && v!=sink { local[v]=k; k+=1 } }
    source_cap: [PF_K]i64 = {}
    sink_cap: [PF_K]i64 = {}
    direct_cap: i64 = 0
    edge_u,edge_v: [PF_M]int = {}, {}
    capacity,flow: [PF_M]i64 = {}, {}
    edge_count:=0
    for i:=0; i<m; i+=1 {
        ur,vr,cap:=input[4+3*i],input[5+3*i],input[6+3*i]
        if ur<1 || ur>nv || vr<1 || vr>nv || ur==vr || cap<0 || cap>100 do return -1
        u,v:=int(ur-1),int(vr-1)
        if u==source { if v==sink { direct_cap+=cap } else { source_cap[local[v]]+=cap } }
        else if v==sink { sink_cap[local[u]]+=cap }
        else if v==source || u==sink do return -1
        else { edge_u[edge_count]=local[u]; edge_v[edge_count]=local[v]; capacity[edge_count]=cap; edge_count+=1 }
    }
    weight: [PF_K]i64 = {}
    balance: [PF_K]i64 = {}
    label: [PF_K]i64 = {}
    ticket: [PF_K]i64 = {}
    root_edge: [PF_K]int = {}
    tree_edges: [PF_N]int = {}
    tree_count:=0
    next_ticket: i64 = 0
    for v:=0; v<k; v+=1 { weight[v]=source_cap[v]-sink_cap[v]; root_edge[v]=1; label[v]=1; ticket[v]=next_ticket; next_ticket+=1 }
    parent: [PF_N+1]int = {}
    parent_edge: [PF_N+1]int = {}
    branch_root: [PF_K]int = {}
    for iteration:=0; iteration<PF_ITERATIONS; iteration+=1 {
        pf_balance(k,edge_count,&weight,&edge_u,&edge_v,&flow,&balance)
        if !pf_build_state(k,&root_edge,&tree_edges,tree_count,&edge_u,&edge_v,&parent,&parent_edge,&branch_root) { return -1 }
        active: [PF_K]int = {}
        strong: [PF_K]int = {}
        old_label:=label
        for r:=0; r<k; r+=1 { if root_edge[r]!=0 && balance[r]>0 { active[r]=1 } }
        for v:=0; v<k; v+=1 { if balance[branch_root[v]]>0 { strong[v]=1 } }
        crossing:=false
        for e:=0; e<edge_count; e+=1 {
            u,v:=edge_u[e],edge_v[e]
            if strong[u]!=0 && strong[v]==0 && capacity[e]-flow[e]>0 { crossing=true }
            if strong[v]!=0 && strong[u]==0 && flow[e]>0 { crossing=true }
        }
        if !crossing {
            cut:=direct_cap
            for v:=0; v<k; v+=1 { if strong[v]!=0 { cut+=sink_cap[v] } else { cut+=source_cap[v] } }
            for e:=0; e<edge_count; e+=1 { if strong[edge_u[e]]!=0 && strong[edge_v[e]]==0 { cut+=capacity[e] } }
            if cut>=0 && cut<=2400 { return cut }; return -1
        }
        strong_root:=-1
        for r:=0; r<k; r+=1 { if active[r]!=0 && (strong_root<0 || label[r]>label[strong_root] || (label[r]==label[strong_root] && ticket[r]<ticket[strong_root])) { strong_root=r } }
        if strong_root<0 { return -1 }
        low: i64 = 1000
        for v:=0; v<k; v+=1 { if branch_root[v]==strong_root && label[v]<low { low=label[v] } }
        tail,head_node,entering:=-1,-1,-1
        for v:=0; v<k && entering<0; v+=1 { if branch_root[v]==strong_root && label[v]==low {
            for e:=0; e<edge_count && entering<0; e+=1 { if !pf_in_tree(&tree_edges,tree_count,e) {
                u,w:=edge_u[e],edge_v[e]
                if u==v && capacity[e]-flow[e]>0 && branch_root[w]!=strong_root && label[w]==low-1 { tail=v; head_node=w; entering=e }
                else if w==v && flow[e]>0 && branch_root[u]!=strong_root && label[u]==low-1 { tail=v; head_node=u; entering=e }
            } }
        } }
        if entering<0 {
            relabel:=-1
            for v:=0; v<k && relabel<0; v+=1 { if branch_root[v]==strong_root && label[v]==low {
                children_ok:=true
                for child:=0; child<k; child+=1 { if parent[child]==v && label[child]<low+1 { children_ok=false } }
                if children_ok { relabel=v }
            } }
            if relabel<0 { return -1 }
            label[relabel]+=1
            if relabel==strong_root { ticket[strong_root]=next_ticket; next_ticket+=1 }
            continue
        }
        target_root:=branch_root[head_node]; root:=k
        chain: [PF_N+1]int = {}; chain_len:=0; cursor:=tail
        for cursor!=root { chain[chain_len]=cursor; chain_len+=1; cursor=parent[cursor] }
        step_from: [2*PF_N+2]int = {}
        step_to: [2*PF_N+2]int = {}
        step_edge: [2*PF_N+2]int = {}
        steps:=0
        for j:=chain_len-1; j>=0; j-=1 { child:=chain[j]; if parent[child]!=root { step_from[steps]=parent[child]; step_to[steps]=child; step_edge[steps]=parent_edge[child]; steps+=1 } }
        step_from[steps]=tail; step_to[steps]=head_node; step_edge[steps]=entering; steps+=1
        cursor=head_node
        for cursor!=target_root { step_from[steps]=cursor; step_to[steps]=parent[cursor]; step_edge[steps]=parent_edge[cursor]; steps+=1; cursor=parent[cursor] }
        root_edge[strong_root]=0; tree_edges[tree_count]=entering; tree_count+=1
        for j:=0; j<chain_len; j+=1 { label[chain[j]]=label[head_node]+1 }
        carry:=balance[strong_root]
        for j:=0; j<steps; j+=1 {
            e:=step_edge[j]; u,v:=edge_u[e],edge_v[e]
            residual:=flow[e]; if step_from[j]==u && step_to[j]==v { residual=capacity[e]-flow[e] }
            pushed:=carry; if residual<pushed { pushed=residual }
            if step_from[j]==u && step_to[j]==v { flow[e]+=pushed } else { flow[e]-=pushed }
            if residual<carry { if !pf_remove_tree_edge(&tree_edges,&tree_count,e) { return -1 }; root_edge[step_from[j]]=1 }
            carry=pushed
            if carry==0 { break }
        }
        pf_balance(k,edge_count,&weight,&edge_u,&edge_v,&flow,&balance)
        if !pf_build_state(k,&root_edge,&tree_edges,tree_count,&edge_u,&edge_v,&parent,&parent_edge,&branch_root) { return -1 }
        for r:=0; r<k; r+=1 { if root_edge[r]!=0 && balance[r]>0 && (active[r]==0 || label[r]!=old_label[r]) { ticket[r]=next_ticket; next_ticket+=1 } }
    }
    return -1
}
