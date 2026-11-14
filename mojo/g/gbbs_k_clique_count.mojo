# Independent bounded GBBS four-clique profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_k_clique_count")
fn gbbs_k_clique_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 24 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var directed = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        degree.append(0)
        directed.append(0)
    for edge in range(Int(mv)):
        let u = input[2+2*edge]
        let v = input[3+2*edge]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
        degree[a] += 1
        degree[b] += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for u in range(n):
        if degree[u] < 3: continue
        for v in range(u+1,n):
            if degree[v] >= 3 and (rows[u] & (1 << v)) != 0: directed[u] |= 1 << v
    var count = Int64(0)
    for a in range(n):
        for b in range(a+1,n):
            if (directed[a] & (1 << b)) == 0: continue
            for c in range(b+1,n):
                if ((directed[a] & directed[b]) & (1 << c)) == 0: continue
                let candidates = directed[a] & directed[b] & directed[c]
                for d in range(c+1,n):
                    if (candidates & (1 << d)) != 0: count += 1
    for byte in range(8): output[byte] = UInt8((count >> (8*byte)) & 255)
    return 8
