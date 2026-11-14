# Independent bounded GBBS k-core profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_k_core_decomposition")
fn gbbs_k_core_decomposition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var core = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        degree.append(0)
        core.append(0)
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
    while active != 0:
        var k = n
        for u in range(n):
            if (active & (1 << u)) != 0 and degree[u] < k: k = degree[u]
        var shell = 0
        for u in range(n):
            if (active & (1 << u)) != 0 and degree[u] == k:
                shell |= 1 << u
                core[u] = k
        active &= ~shell
        for u in range(n):
            if (active & (1 << u)) == 0: continue
            var removed = rows[u] & shell
            var count = 0
            while removed != 0:
                removed &= removed-1
                count += 1
            degree[u] -= count
            if degree[u] < k: degree[u] = k
    for u in range(n):
        let value = Int64(core[u])
        for byte in range(8): output[8*u+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(8*n)
