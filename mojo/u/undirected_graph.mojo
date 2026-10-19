from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime NMAX = 8
comptime FNV_PRIME: UInt64 = 0x100000001b3

fn hash_byte(h: UInt64, b: UInt8) -> UInt64:
    let wide = UInt128(h ^ UInt64(b)) * UInt128(FNV_PRIME)
    return UInt64(wide & UInt128(0xffffffffffffffff))

fn hash_u32(h0: UInt64, x: UInt32) -> UInt64:
    var h = h0
    for i in range(4): h = hash_byte(h, UInt8((x >> (i*8)) & 255))
    return h

fn hash_i32(h0: UInt64, x: Int64) -> UInt64:
    var h = h0
    for i in range(4): h = hash_byte(h, UInt8((x >> (i*8)) & 255))
    return h

fn edge_index(n: Int, a0: Int, b0: Int) -> Int:
    let a = min(a0,b0); let b = max(a0,b0)
    var index = 0
    for i in range(a): index += n-i-1
    return index+b-a-1

fn components(n: Int, adj: InlineArray[UInt8,64]) -> Int:
    var seen = InlineArray[UInt8,8](fill=0); var total = 0
    for root in range(n):
        if seen[root] != 0: continue
        total += 1; seen[root] = 1
        var st = InlineArray[Int,8](fill=0); var size = 1; st[0] = root
        while size > 0:
            size -= 1; let node = st[size]
            for v in range(n):
                if adj[node*8+v] != 0 and seen[v] == 0:
                    seen[v] = 1; st[size] = v; size += 1
    return total

fn prim_mask(n: Int, adj: InlineArray[UInt8,64], w: InlineArray[Int64,64]) -> UInt32:
    var used = InlineArray[UInt8,8](fill=0); var best = InlineArray[Int64,8](fill=0)
    var parent = InlineArray[Int,8](fill=-1); var mask: UInt32 = 0
    for root in range(n):
        if used[root] != 0: continue
        used[root] = 1
        for v in range(n):
            if adj[root*8+v] != 0 and used[v] == 0:
                best[v] = w[root*8+v]; parent[v] = root
        while True:
            var selected = -1
            for v in range(n):
                if used[v] == 0 and parent[v] >= 0 and (selected < 0 or best[v] < best[selected]): selected = v
            if selected < 0: break
            mask = mask | (UInt32(1) << edge_index(n,parent[selected],selected))
            let node = selected; used[node] = 1; parent[node] = -1
            for v in range(n):
                if adj[node*8+v] != 0 and used[v] == 0 and (parent[v] < 0 or w[node*8+v] < best[v]):
                    best[v] = w[node*8+v]; parent[v] = node
    return mask

@export("undirected_graph")
fn undirected_graph(v: UnsafePointer[Int64, ImmutAnyOrigin], n_input: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n_input < 3 or n_input > 599: return -1
    let nv=v[0]; let m=v[1]
    if nv < 0 or nv > 8 or m < 0 or m > 28 or m > nv*(nv-1)/2: return -1
    let qpos=2+3*Int(m)
    if qpos >= Int(n_input): return -1
    let q=v[qpos]
    if q < 0 or q > 128 or n_input != c_size_t(3+3*m+4*q): return -1
    let n=Int(nv)
    var adj=InlineArray[UInt8,64](fill=0); var weights=InlineArray[Int64,64](fill=0)
    for e in range(Int(m)):
        let a=v[2+3*e]; let b=v[3+3*e]; let wt=v[4+3*e]
        if a < 0 or a >= b or b >= nv or wt < -1000000 or wt > 1000000: return -1
        if adj[Int(a)*8+Int(b)] != 0: return -1
        for i in range(n):
            for j in range(i+1,n):
                if adj[i*8+j] != 0 and weights[i*8+j] == wt: return -1
        adj[Int(a)*8+Int(b)]=1; adj[Int(b)*8+Int(a)]=1
        weights[Int(a)*8+Int(b)]=wt; weights[Int(b)*8+Int(a)]=wt
    var hash: UInt64=0xcbf29ce484222325
    for opi in range(Int(q)):
        let at=qpos+1+4*opi; let op=v[at]; let av=v[at+1]; let bv=v[at+2]; let wt=v[at+3]
        var rc: UInt8=0
        if op == 0:
            if av < 0 or av >= nv or bv < 0 or bv >= nv or av == bv or wt < -1000000 or wt > 1000000: return -1
            for i in range(n):
                for j in range(i+1,n):
                    if not (i == min(Int(av),Int(bv)) and j == max(Int(av),Int(bv))) and adj[i*8+j] != 0 and weights[i*8+j] == wt: return -1
            adj[Int(av)*8+Int(bv)]=1; adj[Int(bv)*8+Int(av)]=1
            weights[Int(av)*8+Int(bv)]=wt; weights[Int(bv)*8+Int(av)]=wt
        elif op == 1 or op == 2:
            if av < 0 or av >= nv or bv < 0 or bv >= nv or av == bv or wt != 0: return -1
            if op == 1:
                adj[Int(av)*8+Int(bv)]=0; adj[Int(bv)*8+Int(av)]=0
                weights[Int(av)*8+Int(bv)]=0; weights[Int(bv)*8+Int(av)]=0
            else: rc=adj[Int(av)*8+Int(bv)]
        elif op == 3 or op == 4 or op == 5 or op == 6:
            if av != 0 or bv != 0 or wt != 0: return -1
            hash=hash_byte(hash,UInt8(op)); hash=hash_byte(hash,rc)
            if op == 3: hash=hash_byte(hash,UInt8(components(n,adj)))
            else:
                hash=hash_byte(hash,UInt8(components(n,adj)))
                hash=hash_u32(hash,prim_mask(n,adj,weights))
            continue
        else: return -1
        hash=hash_byte(hash,UInt8(op)); hash=hash_byte(hash,rc)
    var active=0
    for a in range(n):
        for b in range(a+1,n): if adj[a*8+b] != 0: active += 1
    hash=hash_byte(hash,UInt8(n)); hash=hash_byte(hash,UInt8(active))
    for a in range(n):
        for b in range(a+1,n):
            if adj[a*8+b] == 0: continue
            hash=hash_byte(hash,UInt8(a)); hash=hash_byte(hash,UInt8(b))
            hash=hash_i32(hash,weights[a*8+b])
    return Int64(hash & UInt64(0x7fffffffffffffff))
