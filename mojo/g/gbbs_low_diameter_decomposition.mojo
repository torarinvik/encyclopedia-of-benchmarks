# Independent bounded GBBS center-growth profile; see package MIT notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_low_diameter_decomposition")
fn gbbs_low_diameter_decomposition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 50: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 12 or mv < 0 or mv > 24 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var labels = List[Int](capacity=n)
    var reached = List[Int](capacity=n)
    for _ in range(n):
        rows.append(0)
        labels.append(-1)
        reached.append(-1)
    for e in range(Int(mv)):
        let u = input[2+2*e]
        let v = input[3+2*e]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    var batches = List[Int](capacity=13)
    batches.append(1); batches.append(1); batches.append(1); batches.append(1)
    batches.append(2); batches.append(2); batches.append(3); batches.append(4)
    batches.append(4); batches.append(6); batches.append(7); batches.append(9); batches.append(11)
    var frontier = 0
    var cursor = 0
    var assigned = 0
    var round = 0
    while assigned < n:
        var end = cursor+batches[round]
        if end > n: end = n
        for candidate in range(cursor,end):
            if labels[candidate] < 0:
                labels[candidate] = candidate
                frontier |= 1 << candidate
                assigned += 1
        cursor = end
        if assigned == n: break
        for u in range(n): reached[u] = -1
        for u in range(n):
            if (frontier & (1 << u)) == 0: continue
            for v in range(n):
                if (rows[u] & (1 << v)) != 0 and labels[v] < 0 and (reached[v] < 0 or labels[u] < reached[v]): reached[v] = labels[u]
        frontier = 0
        for v in range(n):
            if reached[v] >= 0:
                labels[v] = reached[v]
                frontier |= 1 << v
                assigned += 1
        round += 1
    for u in range(n): output[u] = UInt8(labels[u])
    return Int64(n)
