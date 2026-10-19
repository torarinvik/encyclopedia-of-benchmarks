from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bridge_dfs(u: Int, parent: Int, n: Int, adj: List[Bool], mut disc: List[Int], mut low: List[Int], mut time: Int, mut bridge: List[Bool]) -> None:
    disc[u] = time; low[u] = time; time += 1
    for v in range(n):
        if not adj[u * 64 + v]: continue
        if disc[v] < 0:
            bridge_dfs(v, u, n, adj, disc, low, time, bridge)
            low[u] = min(low[u], low[v])
            if low[v] > disc[u]: bridge[u * 64 + v] = True; bridge[v * 64 + u] = True
        elif v != parent and disc[v] < low[u]: low[u] = disc[v]

@export("bridges")
fn bridges(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 4096: return -1
    let nv = input[0]; let ev = input[1]
    if nv < 0 or nv > 64 or ev < 0 or ev > 2047 or length != c_size_t(2 + 2 * ev): return -1
    let n = Int(nv); var adj = List[Bool](capacity=4096); var bridge = List[Bool](capacity=4096)
    for _ in range(4096): adj.append(False); bridge.append(False)
    for e in range(Int(ev)):
        let a = input[2 + 2 * e]; let b = input[3 + 2 * e]
        if a < 0 or a >= nv or b < 0 or b >= nv: return -1
        adj[Int(a) * 64 + Int(b)] = True; adj[Int(b) * 64 + Int(a)] = True
    var disc = List[Int](capacity=n); var low = List[Int](capacity=n)
    for _ in range(n): disc.append(-1); low.append(0)
    var time = 0
    for u in range(n):
        if disc[u] < 0: bridge_dfs(u, -1, n, adj, disc, low, time, bridge)
    var output_len = 0
    for u in range(n):
        for v in range(u + 1, n):
            if bridge[u * 64 + v]: output_len += 2
    if output_len > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_len)): return -2
    var pos = 0
    for u in range(n):
        for v in range(u + 1, n):
            if bridge[u * 64 + v]: output[pos] = UInt8(u); output[pos + 1] = UInt8(v); pos += 2
    return Int64(output_len)
