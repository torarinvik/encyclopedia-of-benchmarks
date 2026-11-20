from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn pf_build_state(k: Int, root_edge: InlineArray[Int64, 6], tree_edges: InlineArray[Int, 8], tree_count: Int,
                  edge_u: InlineArray[Int, 24], edge_v: InlineArray[Int, 24],
                  mut parent: InlineArray[Int, 9], mut parent_edge: InlineArray[Int, 9],
                  mut branch_root: InlineArray[Int, 6]) -> Bool:
    let root = k
    var adjacency = InlineArray[Int, 81](fill=-2)
    for v in range(k):
        if root_edge[v] != 0:
            adjacency[root*9+v] = -1
            adjacency[v*9+root] = -1
    for i in range(tree_count):
        let e = tree_edges[i]
        let u = edge_u[e]
        let v = edge_v[e]
        adjacency[u*9+v] = e
        adjacency[v*9+u] = e
    for i in range(9):
        parent[i] = -2
        parent_edge[i] = -2
    for i in range(k): branch_root[i] = -1
    var queue = InlineArray[Int, 9](fill=0)
    var head = 0
    var tail = 1
    parent[root] = -1
    queue[0] = root
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(k+1):
            if adjacency[u*9+v] != -2 and parent[v] == -2:
                parent[v] = u
                parent_edge[v] = adjacency[u*9+v]
                branch_root[v] = v if u == root else branch_root[u]
                queue[tail] = v
                tail += 1
    return tail == k+1

fn pf_balance(k: Int, edge_count: Int, weight: InlineArray[Int64, 6], edge_u: InlineArray[Int, 24],
              edge_v: InlineArray[Int, 24], flow: InlineArray[Int64, 24], mut balance: InlineArray[Int64, 6]): None:
    for v in range(k): balance[v] = weight[v]
    for e in range(edge_count):
        balance[edge_u[e]] -= flow[e]
        balance[edge_v[e]] += flow[e]

fn pf_in_tree(tree_edges: InlineArray[Int, 8], tree_count: Int, edge: Int) -> Bool:
    for i in range(tree_count):
        if tree_edges[i] == edge: return True
    return False

fn pf_remove_tree_edge(mut tree_edges: InlineArray[Int, 8], mut tree_count: Int, edge: Int) -> Bool:
    for i in range(tree_count):
        if tree_edges[i] == edge:
            for j in range(i, tree_count-1): tree_edges[j] = tree_edges[j+1]
            tree_count -= 1
            return True
    return False

@export("hochbaum_pseudoflow_maxflow")
fn hochbaum_pseudoflow_maxflow(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 77: return -1
    let nv=input[0]
    let mv=input[1]
    let sr=input[2]
    let tr=input[3]
    if nv<2 or nv>8 or mv<0 or mv>24 or sr<1 or sr>nv or tr<1 or tr>nv or sr==tr: return -1
    let n=Int(nv)
    let m=Int(mv)
    let source=Int(sr-1)
    let sink=Int(tr-1)
    if length != c_size_t(4+3*m): return -1
    var local=InlineArray[Int,8](fill=-1)
    var k=0
    for v in range(n):
        if v!=source and v!=sink:
            local[v]=k
            k+=1
    var source_cap=InlineArray[Int64,6](fill=0)
    var sink_cap=InlineArray[Int64,6](fill=0)
    var direct_cap:Int64=0
    var edge_u=InlineArray[Int,24](fill=0)
    var edge_v=InlineArray[Int,24](fill=0)
    var capacity=InlineArray[Int64,24](fill=0)
    var flow=InlineArray[Int64,24](fill=0)
    var edge_count=0
    for i in range(m):
        let ur=input[4+3*i]
        let vr=input[5+3*i]
        let cap=input[6+3*i]
        if ur<1 or ur>nv or vr<1 or vr>nv or ur==vr or cap<0 or cap>100: return -1
        let u=Int(ur-1)
        let v=Int(vr-1)
        if u==source:
            if v==sink: direct_cap+=cap
            else: source_cap[local[v]]+=cap
        elif v==sink: sink_cap[local[u]]+=cap
        elif v==source or u==sink: return -1
        else:
            edge_u[edge_count]=local[u]
            edge_v[edge_count]=local[v]
            capacity[edge_count]=cap
            edge_count+=1
    var weight=InlineArray[Int64,6](fill=0)
    var balance=InlineArray[Int64,6](fill=0)
    var label=InlineArray[Int64,6](fill=0)
    var ticket=InlineArray[Int64,6](fill=0)
    var next_ticket:Int64=0
    var root_edge=InlineArray[Int64,6](fill=0)
    var tree_edges=InlineArray[Int,8](fill=0)
    var tree_count=0
    for v in range(k):
        weight[v]=source_cap[v]-sink_cap[v]
        root_edge[v]=1
        label[v]=1
        ticket[v]=next_ticket
        next_ticket+=1
    var parent=InlineArray[Int,9](fill=0)
    var parent_edge=InlineArray[Int,9](fill=0)
    var branch_root=InlineArray[Int,6](fill=0)
    for iteration in range(512):
        pf_balance(k,edge_count,weight,edge_u,edge_v,flow,balance)
        if not pf_build_state(k,root_edge,tree_edges,tree_count,edge_u,edge_v,parent,parent_edge,branch_root): return -1
        var active=InlineArray[Int64,6](fill=0)
        var strong=InlineArray[Int64,6](fill=0)
        var old_label=label
        for r in range(k):
            old_label[r]=label[r]
            if root_edge[r]!=0 and balance[r]>0: active[r]=1
        for v in range(k): strong[v]=1 if balance[branch_root[v]]>0 else 0
        var crossing=False
        for e in range(edge_count):
            let u=edge_u[e]
            let v=edge_v[e]
            if strong[u]!=0 and strong[v]==0 and capacity[e]-flow[e]>0: crossing=True
            if strong[v]!=0 and strong[u]==0 and flow[e]>0: crossing=True
        if not crossing:
            var cut=direct_cap
            for v in range(k): cut+=sink_cap[v] if strong[v]!=0 else source_cap[v]
            for e in range(edge_count):
                if strong[edge_u[e]]!=0 and strong[edge_v[e]]==0: cut+=capacity[e]
            return cut if cut>=0 and cut<=2400 else -1
        var strong_root=-1
        for r in range(k):
            if active[r]!=0 and (strong_root<0 or label[r]>label[strong_root] or (label[r]==label[strong_root] and ticket[r]<ticket[strong_root])): strong_root=r
        if strong_root<0: return -1
        var low:Int64=1000
        for v in range(k):
            if branch_root[v]==strong_root and label[v]<low: low=label[v]
        var tail=-1
        var head_node=-1
        var entering=-1
        for v in range(k):
            if entering<0 and branch_root[v]==strong_root and label[v]==low:
                for e in range(edge_count):
                    if entering<0 and not pf_in_tree(tree_edges,tree_count,e):
                        let u=edge_u[e]
                        let w=edge_v[e]
                        if u==v and capacity[e]-flow[e]>0 and branch_root[w]!=strong_root and label[w]==low-1:
                            tail=v;head_node=w;entering=e
                        elif w==v and flow[e]>0 and branch_root[u]!=strong_root and label[u]==low-1:
                            tail=v;head_node=u;entering=e
        if entering<0:
            var relabel=-1
            for v in range(k):
                if relabel<0 and branch_root[v]==strong_root and label[v]==low:
                    var children_ok=True
                    for child in range(k):
                        if parent[child]==v and label[child]<low+1: children_ok=False
                    if children_ok: relabel=v
            if relabel<0: return -1
            label[relabel]+=1
            if relabel==strong_root: ticket[strong_root]=next_ticket;next_ticket+=1
            continue
        let sr_root=strong_root
        let target_root=branch_root[head_node]
        let root=k
        var chain=InlineArray[Int,9](fill=0)
        var chain_len=0
        var cursor=tail
        while cursor!=root: chain[chain_len]=cursor;chain_len+=1;cursor=parent[cursor]
        var step_from=InlineArray[Int,18](fill=0)
        var step_to=InlineArray[Int,18](fill=0)
        var step_edge=InlineArray[Int,18](fill=0)
        var steps=0
        for j in range(chain_len-1,-1,-1):
            let child=chain[j]
            if parent[child]!=root:
                step_from[steps]=parent[child];step_to[steps]=child;step_edge[steps]=parent_edge[child];steps+=1
        step_from[steps]=tail;step_to[steps]=head_node;step_edge[steps]=entering;steps+=1
        cursor=head_node
        while cursor!=target_root:
            step_from[steps]=cursor;step_to[steps]=parent[cursor];step_edge[steps]=parent_edge[cursor];steps+=1;cursor=parent[cursor]
        root_edge[sr_root]=0
        tree_edges[tree_count]=entering;tree_count+=1
        for j in range(chain_len): label[chain[j]]=label[head_node]+1
        var carry=balance[sr_root]
        for j in range(steps):
            let e=step_edge[j]
            let u=edge_u[e]
            let v=edge_v[e]
            let residual=capacity[e]-flow[e] if step_from[j]==u and step_to[j]==v else flow[e]
            let pushed=carry if carry<residual else residual
            if step_from[j]==u and step_to[j]==v: flow[e]+=pushed
            else: flow[e]-=pushed
            if residual<carry:
                if not pf_remove_tree_edge(tree_edges,tree_count,e): return -1
                root_edge[step_from[j]]=1
            carry=pushed
            if carry==0: break
        pf_balance(k,edge_count,weight,edge_u,edge_v,flow,balance)
        if not pf_build_state(k,root_edge,tree_edges,tree_count,edge_u,edge_v,parent,parent_edge,branch_root): return -1
        for r in range(k):
            if root_edge[r]!=0 and balance[r]>0 and (active[r]==0 or label[r]!=old_label[r]): ticket[r]=next_ticket;next_ticket+=1
    return -1
