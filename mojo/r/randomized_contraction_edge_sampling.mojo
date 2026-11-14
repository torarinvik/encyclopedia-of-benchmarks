# One supplied-edge contraction phase and canonical component representatives.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("randomized_contraction_edge_sampling")
fn randomized_contraction_edge_sampling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 74: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 2 or nv > 16 or mv < nv-1 or mv > 24 or length != c_size_t(2+3*mv): return -1
    let n = Int(nv); let m = Int(mv)
    var adjacency = List[Int](capacity=n)
    var parents = List[Int](capacity=n)
    var minimum = List[Int](capacity=n)
    var edge_u = List[Int](capacity=m)
    var edge_v = List[Int](capacity=m)
    var sampled = List[Bool](capacity=m)
    for i in range(n):
        adjacency.append(0); parents.append(i); minimum.append(n)
    for i in range(m):
        let u = input[2+3*i]; let v = input[3+3*i]; let bit = input[4+3*i]
        if u < 0 or u >= v or v >= nv or (bit != 0 and bit != 1): return -1
        let a = Int(u); let b = Int(v)
        if (adjacency[a] & (1 << b)) != 0: return -1
        adjacency[a] |= 1 << b; adjacency[b] |= 1 << a
        edge_u.append(a); edge_v.append(b); sampled.append(bit == 1)
    var reached = 1
    for _ in range(n):
        let before = reached
        for i in range(n):
            if (reached & (1 << i)) != 0: reached |= adjacency[i]
        if reached == before: break
    if reached != (1 << n)-1: return -1
    for i in range(m):
        if not sampled[i]: continue
        var a = edge_u[i]; var b = edge_v[i]
        while parents[a] != a: a = parents[a]
        while parents[b] != b: b = parents[b]
        if a != b: parents[b] = a
    for vertex in range(n):
        var root = vertex
        while parents[root] != root: root = parents[root]
        if vertex < minimum[root]: minimum[root] = vertex
    let bytes = 4*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for vertex in range(n):
        var root = vertex
        while parents[root] != root: root = parents[root]
        let value = Int64(minimum[root])
        for byte in range(4): output[4*vertex+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(bytes)
