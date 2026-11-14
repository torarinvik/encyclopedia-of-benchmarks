# Bounded LDFS ordering and four-vertex certificates.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("ldfs_ordering_certificate")
fn ldfs_ordering_certificate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 10: return -1
    let nv = input[0]
    if nv < 1 or nv > 8 or length != c_size_t(nv + 2): return -1
    let start = input[1]
    if start < 0 or start >= nv: return -1
    let n = Int(nv)
    let all_vertices = (1 << n) - 1
    var rows = List[Int](capacity=n)
    for i in range(n):
        let row = input[i+2]
        if row < 0 or row > Int64(all_vertices) or (row & Int64(1 << i)) != 0: return -1
        rows.append(Int(row))
    for i in range(n):
        for j in range(n):
            if ((rows[i] >> j) & 1) != ((rows[j] >> i) & 1): return -1
    var reached = 1 << Int(start)
    for _ in range(n):
        let old = reached
        for i in range(n):
            if (reached & (1 << i)) != 0: reached |= rows[i]
        if old == reached: break
    if reached != all_vertices: return -1

    var order = List[Int](capacity=n)
    order.append(Int(start))
    var visited = 1 << Int(start)
    while len(order) < n:
        var chosen = -1
        for vertex in range(n):
            if (visited & (1 << vertex)) != 0: continue
            if chosen == -1:
                chosen = vertex
                continue
            var p = len(order)
            while p > 0:
                p -= 1
                let previous = order[p]
                let candidate_bit = (rows[vertex] >> previous) & 1
                let chosen_bit = (rows[chosen] >> previous) & 1
                if candidate_bit != chosen_bit:
                    if candidate_bit > chosen_bit: chosen = vertex
                    break
        order.append(chosen)
        visited |= 1 << chosen

    var fields = List[Int64](capacity=234)
    fields.append(nv)
    for vertex in order: fields.append(Int64(vertex))
    fields.append(0)
    var certificates = 0
    for i in range(n):
        for j in range(i+1, n):
            for k in range(j+1, n):
                let a = order[i]
                let b = order[j]
                let c = order[k]
                if (rows[a] & (1 << c)) == 0 or (rows[a] & (1 << b)) != 0: continue
                var witness = -1
                for t in range(i+1, j):
                    let d = order[t]
                    if (rows[d] & (1 << b)) != 0 and (rows[d] & (1 << c)) == 0:
                        witness = d
                        break
                fields.append(Int64(a))
                fields.append(Int64(b))
                fields.append(Int64(c))
                fields.append(Int64(witness))
                certificates += 1
    fields[n+1] = Int64(certificates)
    let bytes = 8 * len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
