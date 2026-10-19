from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("breadth_first_search_shortest_path_distance")
fn breadth_first_search_shortest_path_distance(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 516: return -1
    let nv = input[0]; let ev = input[1]; let source = input[2]; let target = input[3]
    if nv < 1 or nv > 26 or ev < 0 or ev > 256 or source < 0 or source >= nv or target < 0 or target >= nv or length != c_size_t(4 + 2 * ev): return -1
    let n = Int(nv); var adj = List[Bool](capacity=n * n); var dist = List[Int](capacity=n)
    for _ in range(n * n): adj.append(False)
    for _ in range(n): dist.append(-1)
    for e in range(Int(ev)):
        let u = input[4 + 2 * e]; let v = input[5 + 2 * e]
        if u < 0 or u >= nv or v < 0 or v >= nv: return -1
        adj[Int(u) * n + Int(v)] = True
    var q = List[Int](capacity=n); q.append(Int(source)); dist[Int(source)] = 0; var head = 0
    while head < len(q):
        let u = q[head]; head += 1
        for v in range(n):
            if adj[u * n + v] and dist[v] < 0: dist[v] = dist[u] + 1; q.append(v)
    return Int64(dist[Int(target)])
