# Independent bounded inclusion-exclusion coloring; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("exact_graph_coloring_inclusion_exclusion")
fn exact_graph_coloring_inclusion_exclusion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 44: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 7 or mv < 0 or mv > 21 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    for _ in range(n): rows.append(0)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v < 0 or u >= nv or v >= nv or u == v: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
    let limit = 1 << n
    var counts = List[Int64](capacity=limit)
    for _ in range(limit): counts.append(0)
    counts[0] = 1
    for mask in range(1,limit):
        var vertex = 0
        while (mask & (1 << vertex)) == 0: vertex += 1
        let rest = mask ^ (1 << vertex)
        let allowed = rest & ~rows[vertex]
        counts[mask] = counts[rest] + counts[allowed]
    var chromatic = Int64(n)
    for k in range(1,n+1):
        var total = Int64(0)
        for mask in range(limit):
            let base = counts[mask]-1
            var term = Int64(1)
            for _ in range(k): term *= base
            var bits = mask
            var population = 0
            while bits != 0:
                bits &= bits-1
                population += 1
            if ((n-population) & 1) == 0: total += term
            else: total -= term
        if total > 0:
            chromatic = Int64(k)
            break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for byte in range(8): output[byte] = UInt8((chromatic >> (8*byte)) & 255)
    return 8
