from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn boruvka_root(mut parent: List[Int], node0: Int) -> Int:
    var node = node0
    while parent[node] != node:
        parent[node] = parent[parent[node]]; node = parent[node]
    return node

@export("boruvkas_minimum_spanning_tree")
fn boruvkas_minimum_spanning_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let nv = input[0]; let ev = input[1]
    if nv < 2 or nv > 16 or ev < nv - 1 or ev > 64 or ev > nv * (nv - 1) // 2 or length != c_size_t(2 + 3 * ev): return -1
    let n = Int(nv); let m = Int(ev); var weights = List[Int](capacity=n * n)
    for _ in range(n * n): weights.append(1_000_000)
    for e in range(m):
        let u = input[2 + 3 * e]; let v = input[3 + 3 * e]; let wt = input[4 + 3 * e]
        if u < 1 or u > nv or v < 1 or v > nv or u == v or wt < 1 or wt > 100: return -1
        let a = Int(u - 1); let b = Int(v - 1)
        if weights[a * n + b] != 1_000_000: return -1
        weights[a * n + b] = Int(wt); weights[b * n + a] = Int(wt)
    var parent = List[Int](capacity=n); for i in range(n): parent.append(i)
    var components = n; var total: Int64 = 0
    while components > 1:
        var best_u = List[Int](capacity=n); var best_v = List[Int](capacity=n); var best_w = List[Int](capacity=n)
        for _ in range(n): best_u.append(-1); best_v.append(-1); best_w.append(1_000_000)
        for u in range(n):
            for v in range(u + 1, n):
                let wt = weights[u * n + v]
                if wt == 1_000_000: continue
                let a = boruvka_root(parent, u); let b = boruvka_root(parent, v)
                if a != b:
                    if wt < best_w[a]: best_w[a] = wt; best_u[a] = u; best_v[a] = v
                    if wt < best_w[b]: best_w[b] = wt; best_u[b] = u; best_v[b] = v
        var merged = False
        for r in range(n):
            if best_u[r] >= 0:
                let a = boruvka_root(parent, best_u[r]); let b = boruvka_root(parent, best_v[r])
                if a != b: parent[a] = b; components -= 1; total += Int64(best_w[r]); merged = True
        if not merged: return -1
    return total
