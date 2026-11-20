# Clean-room bounded edge-peeling truss decomposition.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("k_truss_edge_peeling_decomposition")
fn k_truss_edge_peeling_decomposition(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 243: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 120 or
        length != c_size_t(2 + 2 * mv) or length > 242: return -1
    let n = Int(nv)
    let m = Int(mv)
    var rows = List[Int](capacity=n)
    var edgeIndex = List[Int](capacity=256)
    var edgeU = List[Int](capacity=m)
    var edgeV = List[Int](capacity=m)
    var support = List[Int](capacity=m)
    var alive = List[Int](capacity=m)
    var trussness = List[Int](capacity=m)
    for _ in range(n): rows.append(0)
    for _ in range(256): edgeIndex.append(-1)
    for _ in range(m):
        edgeU.append(0)
        edgeV.append(0)
        support.append(0)
        alive.append(0)
        trussness.append(0)
    for edge in range(m):
        let u = input[2 + 2 * edge]
        let v = input[3 + 2 * edge]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if (rows[a] & (1 << b)) != 0: return -1
        rows[a] |= 1 << b
        rows[b] |= 1 << a
        edgeIndex[a * 16 + b] = edge
        edgeIndex[b * 16 + a] = edge
        edgeU[edge] = a
        edgeV[edge] = b
        alive[edge] = 1
    for u in range(n):
        for v in range(u + 1, n):
            for w in range(v + 1, n):
                if ((rows[u] & (1 << v)) != 0 and (rows[u] & (1 << w)) != 0 and
                    (rows[v] & (1 << w)) != 0):
                    support[edgeIndex[u * 16 + v]] += 1
                    support[edgeIndex[u * 16 + w]] += 1
                    support[edgeIndex[v * 16 + w]] += 1
    let outputBytes = 8 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(outputBytes): return -2
    var remaining = m
    var level = 0
    while remaining > 0:
        var selected = -1
        for edge in range(m):
            if alive[edge] != 0 and (selected < 0 or support[edge] < support[selected]): selected = edge
        if support[selected] > level: level = support[selected]
        trussness[selected] = level + 2
        alive[selected] = 0
        remaining -= 1
        let u = edgeU[selected]
        let v = edgeV[selected]
        for w in range(n):
            if w == u or w == v or (rows[u] & (1 << w)) == 0 or (rows[v] & (1 << w)) == 0: continue
            let first = edgeIndex[u * 16 + w]
            let second = edgeIndex[v * 16 + w]
            if alive[first] != 0 and alive[second] != 0:
                if support[first] > level: support[first] -= 1
                if support[second] > level: support[second] -= 1
    for edge in range(m):
        let value = Int64(trussness[edge])
        for byte in range(8): output[8 * edge + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(outputBytes)
