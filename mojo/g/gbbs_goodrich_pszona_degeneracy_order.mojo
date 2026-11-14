# Independent bounded GBBS Goodrich-Pszona profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_goodrich_pszona_degeneracy_order")
fn gbbs_goodrich_pszona_degeneracy_order(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 382: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 20 or mv < 0 or mv > 190 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var rank = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        degree.append(0)
        rank.append(0)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
        degree[a] += 1
        degree[b] += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var active = (1 << n)-1
    for position in range(n):
        var chosen = -1
        for u in range(n):
            if (active & (1 << u)) != 0:
                if chosen == -1 or degree[u] < degree[chosen]: chosen = u
        rank[chosen] = position
        active &= ~(1 << chosen)
        for v in range(n):
            if (active & (1 << v)) != 0 and (rows[chosen] & (1 << v)) != 0: degree[v] -= 1
    for u in range(n):
        let value = Int64(rank[u])
        for byte in range(8): output[8*u+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(8*n)
