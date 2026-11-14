from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("gapbs_betweenness_centrality")
fn gapbs_betweenness_centrality(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 12 or length > 74: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 3 or nv > 8 or kv < 1 or kv > nv: return -1
    let n = Int(nv)
    let k = Int(kv)
    if length != c_size_t(2+k+n*n): return -1
    var sources = List[Int](capacity=8)
    var adjacency = List[Bool](capacity=64)
    var scores = List[Float32](capacity=8)
    for _ in range(64): adjacency.append(False)
    for _ in range(8): scores.append(0.0)
    for i in range(k):
        let source = input[2+i]
        if source < 0 or source >= nv: return -1
        for j in range(i):
            if sources[j] == Int(source): return -1
        sources.append(Int(source))
    for u in range(n):
        for v in range(n):
            let edge = input[2+k+u*n+v]
            if (edge != 0 and edge != 1) or (u == v and edge != 0): return -1
            adjacency[8*u+v] = edge == 1
    for u in range(n):
        for v in range(u+1, n):
            if adjacency[8*u+v] != adjacency[8*v+u]: return -1
    for si in range(k):
        var depth = List[Int](capacity=8)
        var queue = List[Int](capacity=8)
        var paths = List[Float64](capacity=8)
        var delta = List[Float32](capacity=8)
        for _ in range(8):
            depth.append(-1); queue.append(0); paths.append(0.0); delta.append(0.0)
        let source = sources[si]
        depth[source] = 0
        paths[source] = 1.0
        queue[0] = source
        var head = 0
        var tail = 1
        while head < tail:
            let u = queue[head]
            head += 1
            for v in range(n):
                if adjacency[8*u+v]:
                    if depth[v] < 0:
                        depth[v] = depth[u]+1
                        queue[tail] = v
                        tail += 1
                    if depth[v] == depth[u]+1: paths[v] += paths[u]
        var maximum_depth = 0
        for v in range(n): maximum_depth = max(maximum_depth, depth[v])
        var d = maximum_depth
        while d >= 0:
            for u in range(n):
                if depth[u] == d:
                    var du = Float32(0.0)
                    for v in range(n):
                        if adjacency[8*u+v] and depth[v] == d+1:
                            let one_plus = Float32(1.0)+delta[v]
                            let contribution = (paths[u]/paths[v])*Float64(one_plus)
                            du = Float32(Float64(du)+contribution)
                    delta[u] = du
                    scores[u] = Float32(Float64(scores[u])+Float64(du))
            d -= 1
    var biggest = Float32(0.0)
    for v in range(n): biggest = max(biggest, scores[v])
    if biggest <= 0.0: return -1
    var checksum = Int64(0)
    for v in range(n):
        let normalized = scores[v]/biggest
        let rounded = Int64(Float64(normalized)*1000.0+0.5)
        checksum += Int64(v+1)*rounded
    return checksum
