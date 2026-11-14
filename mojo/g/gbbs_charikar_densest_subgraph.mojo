# Independent bounded GBBS Charikar profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gbbs_charikar_densest_subgraph")
fn gbbs_charikar_densest_subgraph(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1.0e300
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1.0e300
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var order = List[Int](capacity=n)
    var position = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        degree.append(0)
        position.append(0)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v <= u or v >= nv: return -1.0e300
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1.0e300
        rows[a] |= 1 << b
        rows[b] |= 1 << a
        degree[a] += 1
        degree[b] += 1
    var active = (1 << n)-1
    while active != 0:
        var level = n
        for u in range(n):
            if (active & (1 << u)) != 0 and degree[u] < level: level = degree[u]
        while True:
            var shell = 0
            for u in range(n):
                if (active & (1 << u)) != 0 and degree[u] == level:
                    shell |= 1 << u
                    order.append(u)
            if shell == 0: break
            active &= ~shell
            for u in range(n):
                if (active & (1 << u)) == 0: continue
                var removed = rows[u] & shell
                var count = 0
                while removed != 0:
                    removed &= removed-1
                    count += 1
                degree[u] -= count
                if degree[u] < level: degree[u] = level
    for i in range(n): position[order[i]] = i
    var best = Float64(0.0)
    for start in range(n):
        var edges = 0
        for u in range(n):
            if position[u] < start: continue
            for v in range(u+1,n):
                if position[v] >= start and (rows[u] & (1 << v)) != 0: edges += 1
        let score = 2.0 * Float64(edges) / Float64(n-start)
        if score > best: best = score
    return best
