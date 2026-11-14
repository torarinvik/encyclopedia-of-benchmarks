# Independent bounded GBBS Barenboim-Elkin profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn population(mask: Int) -> Int:
    var bits = mask
    var count = 0
    while bits != 0:
        bits &= bits-1
        count += 1
    return count

@export("gbbs_barenboim_elkin_degeneracy_order")
fn gbbs_barenboim_elkin_degeneracy_order(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 382: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 20 or mv < 0 or mv > 190 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var initial = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var rank = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        initial.append(0)
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
        initial[a] += 1
        initial[b] += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    for u in range(n): degree[u] = initial[u]
    var active = (1 << n)-1
    var remaining = n
    var best_num = 0
    var best_den = 1
    while remaining > 0:
        var total = 0
        for u in range(n):
            if (active & (1 << u)) != 0: total += degree[u]
        if total*best_den > best_num*remaining:
            best_num = total
            best_den = remaining
        var removed = 0
        for u in range(n):
            if (active & (1 << u)) != 0 and 10*degree[u]*remaining <= 11*total: removed |= 1 << u
        if removed == 0: return -1
        active &= ~removed
        remaining -= population(removed)
        for u in range(n):
            if (active & (1 << u)) != 0: degree[u] -= population(rows[u] & removed)
    var cutoff = (best_num+10*best_den-1) // (10*best_den)
    if cutoff < 1: cutoff = 1
    for u in range(n): degree[u] = initial[u]
    active = (1 << n)-1
    var used = 0
    while active != 0:
        var shell = 0
        for u in range(n):
            if (active & (1 << u)) != 0 and degree[u] < cutoff: shell |= 1 << u
        if shell == 0:
            var u = 0
            while (active & (1 << u)) == 0: u += 1
            shell = 1 << u
        for u in range(n):
            if (shell & (1 << u)) != 0:
                rank[u] = used
                used += 1
        active &= ~shell
        for u in range(n):
            if (active & (1 << u)) != 0: degree[u] -= population(rows[u] & shell)
    for u in range(n):
        let value = Int64(rank[u])
        for byte in range(8): output[8*u+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(8*n)
