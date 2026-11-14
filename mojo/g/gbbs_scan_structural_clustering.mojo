# Independent bounded GBBS SCAN profile; see package MIT notice.
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

@export("gbbs_scan_structural_clustering")
fn gbbs_scan_structural_clustering(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 64 or length != c_size_t(2+2*mv): return -1
    let n = Int(nv)
    var rows = List[Int](capacity=n)
    var degree = List[Int](capacity=n)
    var similar = List[Int](capacity=n)
    var core = List[Bool](capacity=n)
    var labels = List[Int64](capacity=n)
    for _ in range(n):
        rows.append(0)
        degree.append(0)
        similar.append(0)
        core.append(False)
        labels.append(-1)
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
    for u in range(n):
        for v in range(n):
            if (rows[u] & (1 << v)) != 0:
                let num = population(rows[u] & rows[v])+2
                let den = (degree[u]+1)*(degree[v]+1)
                if 4*num*num >= den: similar[u] |= 1 << v
        core[u] = population(similar[u]) >= 2
    for root in range(n):
        if not core[root] or labels[root] != -1: continue
        var queue = List[Int](capacity=n)
        queue.append(root)
        labels[root] = Int64(root)
        var head = 0
        while head < len(queue):
            let u = queue[head]
            head += 1
            for v in range(n):
                if core[v] and labels[v] == -1 and (similar[u] & (1 << v)) != 0:
                    labels[v] = Int64(root)
                    queue.append(v)
    for u in range(n):
        if core[u]: continue
        var best = -1
        var best_num = 0
        var best_den = 1
        for v in range(n):
            if not core[v] or (similar[u] & (1 << v)) == 0: continue
            let num = population(rows[u] & rows[v])+2
            let den = (degree[u]+1)*(degree[v]+1)
            let left = num*num*best_den
            let right = best_num*best_num*den
            if best == -1 or left > right or (left == right and v < best):
                best = v
                best_num = num
                best_den = den
        if best != -1: labels[u] = labels[best]
    for u in range(n):
        for byte in range(8): output[8*u+byte] = UInt8((labels[u] >> (8*byte)) & 255)
    return Int64(8*n)
