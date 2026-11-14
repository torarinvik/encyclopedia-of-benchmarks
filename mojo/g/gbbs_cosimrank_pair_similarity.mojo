# Independent bounded GBBS CoSimRank profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_cosimrank_pair_similarity")
fn gbbs_cosimrank_pair_similarity(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 53: return -1
    let nv = input[0]
    let mv = input[1]
    let su = input[2]
    let sv = input[3]
    let tv = input[4]
    if nv < 1 or nv > 8 or mv < 0 or mv > 24 or su < 0 or su >= nv or sv < 0 or sv >= nv or tv < 1 or tv > 4 or length != c_size_t(5+2*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var rows = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var from_nodes = List[Int](capacity=m)
    var to_nodes = List[Int](capacity=m)
    for _ in range(n):
        rows.append(0)
        degree.append(0)
    for e in range(m):
        let u = input[5+2*e]
        let v = input[6+2*e]
        if u < 0 or u >= nv or v < 0 or v >= nv or u == v: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        degree[a] += 1
        from_nodes.append(a)
        to_nodes.append(b)
    for u in range(n):
        if degree[u] != 0 and degree[u] != 1 and degree[u] != 2 and degree[u] != 4: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var current_u = List[Int](capacity=n)
    var current_v = List[Int](capacity=n)
    var next_u = List[Int](capacity=n)
    var next_v = List[Int](capacity=n)
    for _ in range(n):
        current_u.append(0)
        current_v.append(0)
        next_u.append(0)
        next_v.append(0)
    current_u[Int(su)] = 256
    current_v[Int(sv)] = 256
    var numerator = 0
    if su == sv: numerator = 1 << 20
    for step in range(Int(tv)):
        for e in range(m):
            let a = from_nodes[e]
            let b = to_nodes[e]
            next_u[b] += current_u[a] // degree[a]
            next_v[b] += current_v[a] // degree[a]
        var dot = 0
        for u in range(n): dot += next_u[u]*next_v[u]
        numerator += dot << (3-step)
        for u in range(n):
            current_u[u] = next_u[u]
            current_v[u] = next_v[u]
            next_u[u] = 0
            next_v[u] = 0
    let bits = bitcast[UInt64](Float64(numerator) / Float64(1048576))
    for byte in range(8): output[byte] = UInt8((bits >> (8*byte)) & UInt64(255))
    return 8
