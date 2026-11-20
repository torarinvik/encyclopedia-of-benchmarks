from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias MAX_M = 14
alias MAX_INPUT = 54
alias MAX_OUTPUT = 72
alias INF = Int64(4611686018427387903)

fn find_root(inout parent: List[Int], x0: Int) -> Int:
    var x = x0
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x

fn join(inout parent: List[Int], inout ranks: List[Int], a0: Int, b0: Int) -> Bool:
    var a = find_root(inout parent, a0); var b = find_root(inout parent, b0)
    if a == b: return False
    if ranks[a] < ranks[b]:
        let temp = a; a = b; b = temp
    parent[b] = a
    if ranks[a] == ranks[b]: ranks[a] += 1
    return True

fn put_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("steiner_tree_mehlhorn_voronoi_mst")
fn steiner_tree_mehlhorn_voronoi_mst(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT: return -1
    let n0 = input[0]; let m0 = input[1]; let k0 = input[2]
    if n0 < 2 or n0 > MAX_N or m0 < 1 or m0 > MAX_M or k0 < 2 or k0 > n0: return -1
    let n = Int(n0); let m = Int(m0); let k = Int(k0)
    if Int(length) < 3 + k + 3 * m: return -1
    var terminals = List[Int](length=k, fill=0)
    var terminal = List[Bool](length=n, fill=False)
    var at = 3
    for i in range(k):
        let t0 = input[at]; at += 1
        if t0 < 0 or t0 >= n0 or terminal[Int(t0)]: return -1
        terminals[i] = Int(t0); terminal[Int(t0)] = True
    var eu = List[Int](length=m, fill=0); var ev = List[Int](length=m, fill=0)
    var ew = List[Int64](length=m, fill=0)
    var pair_seen = List[Bool](length=n * n, fill=False)
    for e in range(m):
        let u0 = input[at]; let v0 = input[at + 1]; let w = input[at + 2]; at += 3
        if u0 < 0 or u0 >= v0 or v0 >= n0 or w < 1 or w > 9: return -1
        let u = Int(u0); let v = Int(v0)
        if pair_seen[u * n + v]: return -1
        pair_seen[u * n + v] = True; eu[e] = u; ev[e] = v; ew[e] = w
    if at != Int(length): return -1
    var reached = List[Bool](length=n, fill=False); var queue = List[Int]()
    reached[0] = True; queue.append(0); var head = 0
    while head < len(queue):
        let u = queue[head]; head += 1
        for e in range(m):
            var v = -1
            if eu[e] == u: v = ev[e]
            elif ev[e] == u: v = eu[e]
            if v >= 0 and not reached[v]: reached[v] = True; queue.append(v)
    if len(queue) != n: return -1

    var dist = List[Int64](length=n, fill=INF); var owner = List[Int](length=n, fill=n)
    var pred = List[Int](length=n, fill=-1); var pred_edge = List[Int](length=n, fill=-1)
    var settled = List[Bool](length=n, fill=False)
    for i in range(k): let t = terminals[i]; dist[t] = 0; owner[t] = t
    for _ in range(n):
        var u = -1
        for v in range(n):
            if not settled[v] and (u < 0 or dist[v] < dist[u] or
                (dist[v] == dist[u] and (owner[v] < owner[u] or (owner[v] == owner[u] and v < u)))): u = v
        if u < 0 or dist[u] == INF: break
        settled[u] = True
        for e in range(m):
            var v = -1
            if eu[e] == u: v = ev[e]
            elif ev[e] == u: v = eu[e]
            if v < 0: continue
            let nd = dist[u] + ew[e]
            if nd < dist[v] or (nd == dist[v] and owner[u] < owner[v]):
                dist[v] = nd; owner[v] = owner[u]; pred[v] = u; pred_edge[v] = e
            elif nd == dist[v] and owner[u] == owner[v] and not settled[v] and
                 (pred[v] < 0 or u < pred[v] or (u == pred[v] and e < pred_edge[v])):
                pred[v] = u; pred_edge[v] = e
    for v in range(n):
        if dist[v] == INF or owner[v] == n: return -1

    var has = List[Bool](length=n * n, fill=False)
    var best_w = List[Int64](length=n * n, fill=0)
    var best_left = List[Int](length=n * n, fill=0); var best_right = List[Int](length=n * n, fill=0)
    var best_edge = List[Int](length=n * n, fill=0)
    for e in range(m):
        let u = eu[e]; let v = ev[e]; var a = owner[u]; var b = owner[v]
        if a == b: continue
        var left = u; var right = v
        if a > b:
            let temp = a; a = b; b = temp
            left = v; right = u
        let ix = a * n + b; let candidate = dist[u] + ew[e] + dist[v]
        if not has[ix] or candidate < best_w[ix] or
           (candidate == best_w[ix] and (left < best_left[ix] or
            (left == best_left[ix] and (right < best_right[ix] or
             (right == best_right[ix] and e < best_edge[ix]))))):
            has[ix] = True; best_w[ix] = candidate; best_left[ix] = left
            best_right[ix] = right; best_edge[ix] = e
    var ca = List[Int](); var cb = List[Int](); var cl = List[Int](); var cr = List[Int](); var ce = List[Int]()
    var cw = List[Int64]()
    for a in range(n):
        for b in range(a + 1, n):
            let ix = a * n + b
            if has[ix]: ca.append(a); cb.append(b); cl.append(best_left[ix]); cr.append(best_right[ix]); ce.append(best_edge[ix]); cw.append(best_w[ix])
    for i in range(1, len(ca)):
        let wa=cw[i]; let aa=ca[i]; let bb=cb[i]; let ll=cl[i]; let rr=cr[i]; let ee=ce[i]
        var j=i
        while j>0 and (wa<cw[j-1] or (wa==cw[j-1] and (aa<ca[j-1] or
            (aa==ca[j-1] and (bb<cb[j-1] or (bb==cb[j-1] and
             (ll<cl[j-1] or (ll==cl[j-1] and (rr<cr[j-1] or (rr==cr[j-1] and ee<ce[j-1]))))))))):
            cw[j]=cw[j-1];ca[j]=ca[j-1];cb[j]=cb[j-1];cl[j]=cl[j-1];cr[j]=cr[j-1];ce[j]=ce[j-1];j-=1
        cw[j]=wa;ca[j]=aa;cb[j]=bb;cl[j]=ll;cr[j]=rr;ce[j]=ee
    var parent=List[Int](length=n,fill=0);var ranks=List[Int](length=n,fill=0)
    for v in range(n): parent[v]=v
    var chosen=List[Int]();var i=0
    while i<len(ca) and len(chosen)<k-1:
        if join(inout parent,inout ranks,ca[i],cb[i]):chosen.append(i)
        i+=1
    if len(chosen)!=k-1:return -1
    var used=List[Bool](length=m,fill=False)
    for z in range(len(chosen)):
        let ix=chosen[z];used[ce[ix]]=True;var x=cl[ix]
        while x!=ca[ix]:if pred_edge[x]<0:return -1;used[pred_edge[x]]=True;x=pred[x]
        x=cr[ix]
        while x!=cb[ix]:if pred_edge[x]<0:return -1;used[pred_edge[x]]=True;x=pred[x]
    var order=List[Int]();for e in range(m):if used[e]:order.append(e)
    for z in range(1,len(order)):
        let x=order[z];var j=z
        while j>0 and (ew[x]<ew[order[j-1]] or (ew[x]==ew[order[j-1]] and x<order[j-1])):order[j]=order[j-1];j-=1
        order[j]=x
    for v in range(n):parent[v]=v;ranks[v]=0
    var tree=List[Bool](length=m,fill=False)
    for z in range(len(order)):
        let e=order[z]
        if join(inout parent,inout ranks,eu[e],ev[e]):tree[e]=True
    let root=find_root(inout parent,terminals[0])
    for i in range(1,k):if find_root(inout parent,terminals[i])!=root:return -1
    var degree=List[Int](length=n,fill=0)
    for e in range(m):if tree[e]:degree[eu[e]]+=1;degree[ev[e]]+=1
    var leaves=List[Int]();var queued=List[Bool](length=n,fill=False)
    for v in range(n):if not terminal[v] and degree[v]<=1:leaves.append(v);queued[v]=True
    head=0
    while head<len(leaves):
        let u=leaves[head];head+=1
        if degree[u]>1:continue
        for e in range(m):
            if tree[e] and (eu[e]==u or ev[e]==u):
                tree[e]=False;var v=eu[e];if v==u:v=ev[e];degree[u]-=1;degree[v]-=1
                if not terminal[v] and degree[v]<=1 and not queued[v]:leaves.append(v);queued[v]=True
    var result=List[Int]();var cost=Int64(0)
    for e in range(m):if tree[e]:result.append(e);cost+=ew[e]
    if len(result)==0 or len(result)>n-1:return -1
    let bytes=(2+len(result))*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes) or bytes>MAX_OUTPUT:return -2
    put_i64(output,0,cost);put_i64(output,8,Int64(len(result)))
    for i in range(len(result)):put_i64(output,16+i*8,Int64(result[i]))
    return Int64(bytes)
