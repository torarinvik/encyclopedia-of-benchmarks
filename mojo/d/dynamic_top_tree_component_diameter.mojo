from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_N = 16
comptime MAX_Q = 32
comptime MAX_E = 15
comptime MAX_NODES = 75
comptime MAX_INPUT = 143
comptime WEIGHT_LIMIT = Int64(1000)
comptime EDGE_BASE = 0
comptime EDGE_COMPRESS = 1
comptime RAKE_ZERO = 2
comptime RAKE_MERGE = 3
comptime RAKE_BRANCH = 4

struct Cluster(Copyable):
    var kind: Int
    var a: Int
    var b: Int
    var c: Int
    var parent: Int
    var end0: Int
    var end1: Int
    var pivot: Int
    var edge: Int
    var length: Int64
    var far0: Int64
    var far1: Int64
    var diameter: Int64
    var best1: Int64
    var best2: Int64

fn tt_far(nodes: InlineArray[Cluster, MAX_NODES], id: Int, vertex: Int) -> Int64:
    if nodes[id].end0 == vertex: return nodes[id].far0
    return nodes[id].far1

fn tt_recalc(mut nodes: InlineArray[Cluster, MAX_NODES], id: Int,
             weights: InlineArray[Int64, MAX_E]):
    let x = nodes[id]
    if x.kind == EDGE_BASE:
        let w = weights[x.edge]
        nodes[id].length = w
        nodes[id].far0 = w
        nodes[id].far1 = w
        nodes[id].diameter = w
    elif x.kind == RAKE_ZERO:
        nodes[id].best1 = 0
        nodes[id].best2 = 0
        nodes[id].diameter = 0
    elif x.kind == RAKE_MERGE:
        let l = nodes[x.a]
        let r = nodes[x.b]
        var first = Int64(0)
        var second = Int64(0)
        var arms = InlineArray[Int64, 4]()
        arms[0] = l.best1
        arms[1] = l.best2
        arms[2] = r.best1
        arms[3] = r.best2
        for i in range(4):
            let arm = arms[i]
            if arm >= first:
                second = first
                first = arm
            elif arm > second:
                second = arm
        nodes[id].best1 = first
        nodes[id].best2 = second
        nodes[id].diameter = max(l.diameter, max(r.diameter, l.best1 + r.best1))
    elif x.kind == RAKE_BRANCH:
        let e = nodes[x.a]
        let local = nodes[x.b]
        let center = tt_far(nodes, x.a, x.end0)
        let pivot_far = tt_far(nodes, x.a, x.pivot)
        nodes[id].best1 = max(center, e.length + local.best1)
        nodes[id].best2 = 0
        nodes[id].diameter = max(e.diameter, max(local.diameter, pivot_far + local.best1))
    else:
        let first = nodes[x.a]
        let second = nodes[x.b]
        let local = nodes[x.c]
        let ay = tt_far(nodes, x.a, x.end0)
        let ap = tt_far(nodes, x.a, x.pivot)
        let bp = tt_far(nodes, x.b, x.pivot)
        let bz = tt_far(nodes, x.b, x.end1)
        nodes[id].length = first.length + second.length
        nodes[id].far0 = max(ay, first.length + max(bp, local.best1))
        nodes[id].far1 = max(bz, second.length + max(ap, local.best1))
        nodes[id].diameter = max(first.diameter, max(second.diameter,
            max(local.diameter, max(ap + bp, max(ap + local.best1, bp + local.best1)))))

fn tt_append(mut nodes: InlineArray[Cluster, MAX_NODES], inout count: Int,
             kind: Int, weights: InlineArray[Int64, MAX_E], a: Int, b: Int, c: Int,
             end0: Int, end1: Int, pivot: Int, edge: Int) -> Int:
    if count >= MAX_NODES: return -1
    let id = count
    count += 1
    nodes[id].kind = kind
    nodes[id].a = a
    nodes[id].b = b
    nodes[id].c = c
    nodes[id].parent = -1
    nodes[id].end0 = end0
    nodes[id].end1 = end1
    nodes[id].pivot = pivot
    nodes[id].edge = edge
    nodes[id].length = 0
    nodes[id].far0 = 0
    nodes[id].far1 = 0
    nodes[id].diameter = 0
    nodes[id].best1 = 0
    nodes[id].best2 = 0
    if a >= 0: nodes[a].parent = id
    if b >= 0: nodes[b].parent = id
    if c >= 0: nodes[c].parent = id
    tt_recalc(mut nodes, id, weights)
    return id

fn tt_make_rake(mut nodes: InlineArray[Cluster, MAX_NODES], inout node_count: Int,
                weights: InlineArray[Int64, MAX_E], base: Int,
                branches: InlineArray[Int, MAX_N], branch_count: Int) -> Int:
    var level = InlineArray[Int, MAX_N + 1]()
    var next = InlineArray[Int, MAX_N + 1]()
    var count = 1
    level[0] = base
    for i in range(branch_count):
        level[count] = branches[i]
        count += 1
    while count > 1:
        var next_count = 0
        var i = 0
        while i < count:
            if i + 1 == count:
                next[next_count] = level[i]
                next_count += 1
            else:
                let merged = tt_append(mut nodes, inout node_count, RAKE_MERGE, weights,
                    level[i], level[i+1], -1, -1, -1, -1, -1)
                if merged < 0: return -1
                next[next_count] = merged
                next_count += 1
            i += 2
        for j in range(next_count): level[j] = next[j]
        count = next_count
    return level[0]

fn tt_neighbors(adj: InlineArray[Bool, MAX_N * MAX_N], active: InlineArray[Bool, MAX_N],
                n: Int, vertex: Int, mut output: InlineArray[Int, 2]) -> Int:
    var count = 0
    for other in range(n):
        if active[other] and adj[vertex * MAX_N + other]:
            if count < 2: output[count] = other
            count += 1
    return count

fn tt_find(mut parent: InlineArray[Int, MAX_N], vertex: Int) -> Int:
    var v = vertex
    while parent[v] != v:
        parent[v] = parent[parent[v]]
        v = parent[v]
    return v

fn tt_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("dynamic_top_tree_component_diameter")
fn dynamic_top_tree_component_diameter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let nn = input[0]
    let qq = input[1]
    if nn < 1 or nn > MAX_N or qq < 0 or qq > MAX_Q: return -1
    let n = Int(nn)
    let q = Int(qq)
    let edge_end = 2 + 3 * (n - 1)
    if length != c_size_t(edge_end + 3 * q): return -1
    var edge_u = InlineArray[Int, MAX_E]()
    var edge_v = InlineArray[Int, MAX_E]()
    var dsu = InlineArray[Int, MAX_N]()
    var weights = InlineArray[Int64, MAX_E]()
    for v in range(n): dsu[v] = v
    for e in range(n - 1):
        let off = 2 + 3 * e
        let uv = input[off]
        let vv = input[off + 1]
        let w = input[off + 2]
        if uv < 0 or uv >= nn or vv < 0 or vv >= nn or uv == vv or w < 0 or w > WEIGHT_LIMIT: return -1
        let u = Int(uv)
        let v = Int(vv)
        let ru = tt_find(mut dsu, u)
        let rv = tt_find(mut dsu, v)
        if ru == rv: return -1
        dsu[ru] = rv
        edge_u[e] = u
        edge_v[e] = v
        weights[e] = w
    let tree_root = tt_find(mut dsu, 0)
    for v in range(1, n):
        if tt_find(mut dsu, v) != tree_root: return -1

    var op_code = InlineArray[Int, MAX_Q]()
    var op_edge = InlineArray[Int, MAX_Q]()
    var op_value = InlineArray[Int64, MAX_Q]()
    var query_count = 0
    for t in range(q):
        let off = edge_end + 3 * t
        let opcode = input[off]
        let edge = input[off + 1]
        let value = input[off + 2]
        if opcode == 0:
            if edge < 0 or edge >= n - 1 or value < 0 or value > WEIGHT_LIMIT: return -1
        elif opcode == 1:
            if edge != 0 or value != 0: return -1
            query_count += 1
        else: return -1
        op_code[t] = Int(opcode)
        op_edge[t] = Int(edge)
        op_value[t] = value
    let output_bytes = 8 * query_count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)): return -2

    var nodes = InlineArray[Cluster, MAX_NODES]()
    var node_count = 0
    var base_rake = InlineArray[Int, MAX_N]()
    var base_edge = InlineArray[Int, MAX_E]()
    var adj = InlineArray[Bool, MAX_N * MAX_N]()
    var active = InlineArray[Bool, MAX_N]()
    var edge_cluster = InlineArray[Int, MAX_N * MAX_N]()
    var branches = InlineArray[InlineArray[Int, MAX_N], MAX_N]()
    var branch_count = InlineArray[Int, MAX_N]()
    for i in range(MAX_N * MAX_N): edge_cluster[i] = -1
    for v in range(n):
        active[v] = True
        base_rake[v] = tt_append(mut nodes, inout node_count, RAKE_ZERO, weights,-1,-1,-1,-1,-1,-1,-1)
        if base_rake[v] < 0: return -1
    for e in range(n - 1):
        let u = edge_u[e]
        let v = edge_v[e]
        let cluster = tt_append(mut nodes,inout node_count,EDGE_BASE,weights,-1,-1,-1,u,v,-1,e)
        if cluster < 0: return -1
        base_edge[e] = cluster
        adj[u * MAX_N + v] = True
        adj[v * MAX_N + u] = True
        edge_cluster[u * MAX_N + v] = cluster
        edge_cluster[v * MAX_N + u] = cluster

    var active_count = n
    while active_count > 1:
        if active_count == 2:
            var pair = InlineArray[Int, 2]()
            var found = 0
            for v in range(n):
                if active[v]: pair[found] = v; found += 1
            let x = pair[0]
            let y = pair[1]
            let local = tt_make_rake(mut nodes,inout node_count,weights,base_rake[x],branches[x],branch_count[x])
            if local < 0: return -1
            let branch = tt_append(mut nodes,inout node_count,RAKE_BRANCH,weights,edge_cluster[x*MAX_N+y],local,-1,y,-1,x,-1)
            if branch < 0 or branch_count[y] >= MAX_N: return -1
            branches[y][branch_count[y]] = branch
            branch_count[y] += 1
            adj[x*MAX_N+y] = False; adj[y*MAX_N+x] = False
            edge_cluster[x*MAX_N+y] = -1; edge_cluster[y*MAX_N+x] = -1
            active[x] = False; active_count -= 1
            break
        var leaves = InlineArray[Int, MAX_N]()
        var leaf_neighbor = InlineArray[Int, MAX_N]()
        var leaf_count = 0
        for v in range(n):
            if active[v]:
                var adjacent = InlineArray[Int, 2]()
                if tt_neighbors(adj,active,n,v,mut adjacent)==1:
                    leaves[leaf_count]=v;leaf_neighbor[leaf_count]=adjacent[0];leaf_count+=1
        for i in range(leaf_count):
            let x=leaves[i];let y=leaf_neighbor[i]
            let local=tt_make_rake(mut nodes,inout node_count,weights,base_rake[x],branches[x],branch_count[x])
            if local<0:return -1
            let branch=tt_append(mut nodes,inout node_count,RAKE_BRANCH,weights,edge_cluster[x*MAX_N+y],local,-1,y,-1,x,-1)
            if branch<0 or branch_count[y]>=MAX_N:return -1
            branches[y][branch_count[y]]=branch;branch_count[y]+=1
        for i in range(leaf_count):
            let x=leaves[i];let y=leaf_neighbor[i]
            adj[x*MAX_N+y]=False;adj[y*MAX_N+x]=False
            edge_cluster[x*MAX_N+y]= -1;edge_cluster[y*MAX_N+x]= -1
            active[x]=False;active_count-=1
        if active_count<=1:break
        var chosen=InlineArray[Bool,MAX_N]()
        var cv=InlineArray[Int,MAX_N]();var cc=0
        for x in range(n):
            if active[x]:
                var a=InlineArray[Int,2]()
                if tt_neighbors(adj,active,n,x,mut a)!=2:continue
                if not chosen[a[0]] and not chosen[a[1]]:chosen[x]=True;cv[cc]=x;cc+=1
        var px=InlineArray[Int,MAX_N]();var py=InlineArray[Int,MAX_N]();var pz=InlineArray[Int,MAX_N]();var pc=InlineArray[Int,MAX_N]()
        for i in range(cc):
            let x=cv[i];var a=InlineArray[Int,2]();_=tt_neighbors(adj,active,n,x,mut a)
            let y=a[0];let z=a[1]
            let local=tt_make_rake(mut nodes,inout node_count,weights,base_rake[x],branches[x],branch_count[x])
            if local<0:return -1
            let cluster=tt_append(mut nodes,inout node_count,EDGE_COMPRESS,weights,edge_cluster[y*MAX_N+x],edge_cluster[x*MAX_N+z],local,y,z,x,-1)
            if cluster<0:return -1
            px[i]=x;py[i]=y;pz[i]=z;pc[i]=cluster
        for i in range(cc):
            let x=px[i];let y=py[i];let z=pz[i]
            adj[y*MAX_N+x]=False;adj[x*MAX_N+y]=False;adj[x*MAX_N+z]=False;adj[z*MAX_N+x]=False
            edge_cluster[y*MAX_N+x]= -1;edge_cluster[x*MAX_N+y]= -1;edge_cluster[x*MAX_N+z]= -1;edge_cluster[z*MAX_N+x]= -1
            active[x]=False;active_count-=1
        for i in range(cc):
            let y=py[i];let z=pz[i]
            adj[y*MAX_N+z]=True;adj[z*MAX_N+y]=True
            edge_cluster[y*MAX_N+z]=pc[i];edge_cluster[z*MAX_N+y]=pc[i]
    var root_vertex=0
    while not active[root_vertex]:root_vertex+=1
    let root=tt_make_rake(mut nodes,inout node_count,weights,base_rake[root_vertex],branches[root_vertex],branch_count[root_vertex])
    if root<0:return -1
    var staged=InlineArray[Int64,MAX_Q]();var staged_count=0
    for t in range(q):
        if op_code[t]==0:
            let edge=op_edge[t];weights[edge]=op_value[t]
            var node=base_edge[edge];tt_recalc(mut nodes,node,weights)
            var ancestor=nodes[node].parent
            while ancestor>=0:node=ancestor;tt_recalc(mut nodes,node,weights);ancestor=nodes[node].parent
        else:staged[staged_count]=nodes[root].diameter;staged_count+=1
    for i in range(staged_count):tt_store(output,8*i,staged[i])
    return Int64(output_bytes)
