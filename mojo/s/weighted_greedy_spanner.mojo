from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("weighted_greedy_spanner")
fn weighted_greedy_spanner(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 87: return -1
    let nv = input[0]
    let mv = input[1]
    let k = input[2]
    if nv < 2 or nv > 8 or mv < 0 or mv > 28 or k < 1 or k > 3 or length != c_size_t(3 + 3 * mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var us = InlineArray[Int, 28](fill=0)
    var vs = InlineArray[Int, 28](fill=0)
    var weights = InlineArray[Int64, 28](fill=0)
    var order = InlineArray[Int, 28](fill=0)
    var seen = InlineArray[Bool, 64](fill=False)
    for i in range(m):
        let u = input[3 + 3 * i]
        let v = input[4 + 3 * i]
        let weight = input[5 + 3 * i]
        if u < 0 or v <= u or v >= nv or weight < 1 or weight > 32: return -1
        let key = 8 * Int(u) + Int(v)
        if seen[key]: return -1
        seen[key] = True
        us[i] = Int(u)
        vs[i] = Int(v)
        weights[i] = weight
        order[i] = i
    for i in range(1, m):
        let edge = order[i]
        var position = i
        while position > 0:
            let prior = order[position - 1]
            let earlier = weights[edge] < weights[prior] or (weights[edge] == weights[prior] and (us[edge] < us[prior] or (us[edge] == us[prior] and vs[edge] < vs[prior])))
            if not earlier: break
            order[position] = prior
            position -= 1
        order[position] = edge
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(m): return -2
    var adjacency = InlineArray[Int64, 64](fill=0)
    var selected = InlineArray[UInt8, 28](fill=0)
    for i in range(m):
        let edge = order[i]
        let source = us[edge]
        let target = vs[edge]
        var distance = InlineArray[Int64, 8](fill=1152921504606846976)
        var settled = InlineArray[Bool, 8](fill=False)
        distance[source] = 0
        for _ in range(n):
            var vertex = n
            var best: Int64 = 1152921504606846976
            for v in range(n):
                if not settled[v] and distance[v] < best:
                    best = distance[v]
                    vertex = v
            if vertex == n: break
            settled[vertex] = True
            for v in range(n):
                let weight = adjacency[8 * vertex + v]
                if weight > 0 and distance[v] > best + weight: distance[v] = best + weight
        if distance[target] > (2 * k - 1) * weights[edge]:
            selected[edge] = 1
            adjacency[8 * source + target] = weights[edge]
            adjacency[8 * target + source] = weights[edge]
    for i in range(m): output[i] = selected[i]
    return Int64(m)
