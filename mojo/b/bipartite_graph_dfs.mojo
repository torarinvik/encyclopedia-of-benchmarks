from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("bipartite_graph_dfs")
fn bipartite_graph_dfs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 514: return -1
    let nv = input[0]; let ev = input[1]
    if nv < 1 or nv > 64 or ev < 0 or ev > 256 or length != c_size_t(2 + 2 * ev): return -1
    let n = Int(nv); var adj = List[Bool](capacity=n * n); var color = List[Int](capacity=n)
    for _ in range(n * n): adj.append(False)
    for _ in range(n): color.append(-1)
    for i in range(Int(ev)):
        let u = input[2 + 2 * i]; let v = input[3 + 2 * i]
        if u < 0 or u >= nv or v < 0 or v >= nv: return -1
        adj[Int(u) * n + Int(v)] = True; adj[Int(v) * n + Int(u)] = True
    for root in range(n):
        if color[root] >= 0: continue
        color[root] = 0; var stack = List[Int](capacity=n); stack.append(root)
        while len(stack) > 0:
            let u = stack.pop()
            for v in range(n):
                if not adj[u * n + v]: continue
                if color[v] < 0: color[v] = 1 - color[u]; stack.append(v)
                elif color[v] == color[u]: return 0
    return 1
