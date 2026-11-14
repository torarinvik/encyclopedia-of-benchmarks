# Independent bounded GBBS BKV12 profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("gbbs_bkv12_densest_subgraph")
fn gbbs_bkv12_densest_subgraph(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 132: return -1.0e300
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1.0e300
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        degree.append(0)
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
    var remaining = n
    var best = Float64(0.0)
    while remaining > 0:
        var total = 0
        for u in range(n):
            if (active & (1 << u)) != 0: total += degree[u]
        let score = Float64(total)/Float64(remaining)
        if score > best: best = score
        var removed = 0
        var count = 0
        for u in range(n):
            if (active & (1 << u)) != 0 and 1000*degree[u]*remaining <= 1001*total:
                removed |= 1 << u
                count += 1
        if count == 0: return -1.0e300
        active &= ~removed
        remaining -= count
        for u in range(n):
            if (active & (1 << u)) == 0: continue
            var incident = rows[u] & removed
            while incident != 0:
                incident &= incident-1
                degree[u] -= 1
    return best
