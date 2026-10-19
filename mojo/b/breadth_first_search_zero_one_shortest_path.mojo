from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("breadth_first_search_zero_one_shortest_path")
fn breadth_first_search_zero_one_shortest_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 772: return -2
    let nv = input[0]; let ev = input[1]; let sv = input[2]; let fv = input[3]
    if nv < 1 or nv > 64 or ev < 0 or ev > 256 or length != c_size_t(4 + 3 * ev) or sv < 0 or sv >= nv or fv < 0 or fv >= nv: return -2
    let n = Int(nv); var adj = List[List[Int]](capacity=n); var weights = List[List[Int]](capacity=n)
    for _ in range(n): adj.append(List[Int](capacity=8)); weights.append(List[Int](capacity=8))
    for e in range(Int(ev)):
        let u = input[4 + 3 * e]; let v = input[5 + 3 * e]; let wt = input[6 + 3 * e]
        if u < 0 or u >= nv or v < 0 or v >= nv or (wt != 0 and wt != 1): return -2
        adj[Int(u)].append(Int(v)); weights[Int(u)].append(Int(wt))
    var dist = List[Int](capacity=n); for _ in range(n): dist.append(1_000_000)
    var deque = List[Int](capacity=131072); for _ in range(131072): deque.append(0)
    let qcap = len(deque); var head = 0; var qcount = 1; deque[0] = Int(sv); dist[Int(sv)] = 0
    while qcount > 0:
        let u = deque[head]; head = (head + 1) % qcap; qcount -= 1
        for i in range(len(adj[u])):
            let v = adj[u][i]; let candidate = dist[u] + weights[u][i]
            if candidate < dist[v]:
                dist[v] = candidate
                if weights[u][i] == 0: head = (head + qcap - 1) % qcap; deque[head] = v
                else: deque[(head + qcount) % qcap] = v
                qcount += 1
    return -1 if dist[Int(fv)] == 1_000_000 else Int64(dist[Int(fv)])
