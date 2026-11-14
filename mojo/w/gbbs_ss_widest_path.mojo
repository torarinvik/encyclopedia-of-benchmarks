# Independent bounded GBBS widest-path profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_ss_widest_path")
fn gbbs_ss_widest_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 195: return -1
    let nv = input[0]
    let mv = input[1]
    let source = input[2]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or source < 0 or source >= nv or length != c_size_t(3+3*mv): return -1
    let n = Int(nv)
    let m = Int(mv)
    var from_nodes = List[Int](capacity=m)
    var to_nodes = List[Int](capacity=m)
    var capacities = List[Int64](capacity=m)
    for e in range(m):
        let u = input[3+3*e]
        let v = input[4+3*e]
        let w = input[5+3*e]
        if u < 0 or u >= nv or v < 0 or v >= nv or w < 1 or w > 32: return -1
        from_nodes.append(Int(u))
        to_nodes.append(Int(v))
        capacities.append(w)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var width = List[Int64](capacity=n)
    var settled = List[Bool](capacity=n)
    for _ in range(n):
        width.append(0)
        settled.append(False)
    width[Int(source)] = 2147483647
    for _ in range(n):
        var chosen = -1
        for u in range(n):
            if not settled[u]:
                if chosen == -1 or width[u] > width[chosen]: chosen = u
        if chosen == -1 or width[chosen] == 0: break
        settled[chosen] = True
        for e in range(m):
            let v = to_nodes[e]
            if from_nodes[e] != chosen or settled[v]: continue
            var candidate = width[chosen]
            if capacities[e] < candidate: candidate = capacities[e]
            if candidate > width[v]: width[v] = candidate
    for u in range(n):
        for byte in range(8): output[8*u+byte] = UInt8((width[u] >> (8*byte)) & 255)
    return Int64(8*n)
