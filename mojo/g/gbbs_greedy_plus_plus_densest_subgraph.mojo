# Independent bounded GBBS GreedyPlusPlus profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gbbs_greedy_plus_plus_densest_subgraph")
fn gbbs_greedy_plus_plus_densest_subgraph(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 132: return -1.0e300
    let nv = input[0]
    let mv = input[1]
    if nv < 10 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1.0e300
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var load = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        load.append(0)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v <= u or v >= nv: return -1.0e300
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1.0e300
        rows[a] |= 1 << b
        rows[b] |= 1 << a
        load[a] += 1
        load[b] += 1
    var best = Float64(0.0)
    for _ in range(20):
        var degree = List[Int](capacity=n)
        var order = List[Int](capacity=n)
        var position = List[Int](capacity=n)
        var density = List[Int](capacity=n)
        for u in range(n):
            degree.append(load[u])
            position.append(0)
            density.append(0)
        var active = (1 << n)-1
        while active != 0:
            var level = 1000000
            for u in range(n):
                if (active & (1 << u)) != 0 and degree[u] < level: level = degree[u]
            var shell = 0
            for u in range(n):
                if (active & (1 << u)) != 0 and degree[u] == level:
                    shell |= 1 << u
                    order.append(u)
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
        for v in range(n):
            var later = 0
            for u in range(n):
                if (rows[v] & (1 << u)) != 0 and position[u] > position[v]: later += 1
            density[position[v]] = 2*later
            load[v] += later
        var sum = 0
        var i = n-1
        while i >= 0:
            sum += density[i]
            let score = Float64(sum)/Float64(n-i)
            if score > best: best = score
            i -= 1
    return best
