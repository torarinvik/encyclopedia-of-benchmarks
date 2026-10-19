from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(mut out: List[UInt8], v: Int64):
    var bits = v
    for _ in range(8): out.append(UInt8(bits & 255)); bits >>= 8

@export("bfs_graph_coloring")
fn bfs_graph_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let nv = input[0]; let ne = input[1]
    if nv < 0 or nv > 64 or ne < 0 or ne > 2016 or length != c_size_t(2 + 2 * ne): return -1
    let n = Int(nv)
    var adj = List[Bool](capacity=64 * 64); var deg = List[Int](capacity=64)
    for _ in range(64 * 64): adj.append(False)
    for _ in range(64): deg.append(0)
    for i in range(Int(ne)):
        let a = input[2 + 2 * i]; let b = input[3 + 2 * i]
        if a < 0 or a >= nv or b < 0 or b >= nv or a == b or adj[Int(a) * 64 + Int(b)]: return -1
        adj[Int(a) * 64 + Int(b)] = True; adj[Int(b) * 64 + Int(a)] = True
        deg[Int(a)] += 1; deg[Int(b)] += 1
    var visited = List[Bool](capacity=64); var colors = List[Int64](capacity=64)
    for _ in range(64): visited.append(False); colors.append(1)
    var q = List[Int](capacity=64)
    for start in range(n):
        if visited[start]: continue
        var high_degree = 0; q = List[Int](capacity=64); q.append(start); visited[start] = True; var head = 0
        while head < len(q):
            let u = q[head]; head += 1
            if deg[u] > 1: high_degree += 1
            for v in range(n):
                if adj[u * 64 + v] and not visited[v]: visited[v] = True; q.append(v)
        if high_degree > 1: return -1
    for i in range(64): visited[i] = False
    for start in range(n):
        if visited[start]: continue
        q = List[Int](capacity=64); q.append(start); visited[start] = True; var head = 0
        while head < len(q):
            let u = q[head]; head += 1
            for v in range(n):
                if not adj[u * 64 + v]: continue
                if colors[v] == colors[u]: colors[v] += 1
                if not visited[v]: visited[v] = True; q.append(v)
    var used: Int64 = 0
    var bytes = List[UInt8](capacity=(n + 2) * 8)
    put_word(bytes, nv)
    for v in range(n): put_word(bytes, colors[v]); used = max(used, colors[v])
    put_word(bytes, used)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
