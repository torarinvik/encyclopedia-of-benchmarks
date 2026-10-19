from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(mut out: List[UInt8], v: Int64):
    var bits = v
    for _ in range(8): out.append(UInt8(bits & 255)); bits >>= 8

@export("bfs_connected_undirected_visit_order")
fn bfs_connected_undirected_visit_order(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let nv = input[0]; let ne = input[1]
    if nv < 1 or nv > 40 or ne < 0 or ne > 780 or input[2] != 0 or length != c_size_t(3 + 2 * ne): return -1
    let n = Int(nv)
    var adj = List[UInt64](capacity=n)
    var seen = List[Bool](capacity=n)
    for _ in range(n): adj.append(0); seen.append(False)
    for i in range(Int(ne)):
        let a = input[3 + 2 * i]; let b = input[4 + 2 * i]
        if a < 0 or a >= nv or b < 0 or b >= nv: return -1
        adj[Int(a)] |= UInt64(1) << Int(b); adj[Int(b)] |= UInt64(1) << Int(a)
    var q = List[Int](capacity=n); var order = List[Int64](capacity=n)
    seen[0] = True; q.append(0); var head = 0
    while head < len(q):
        let u = q[head]; head += 1; order.append(Int64(u))
        for v in range(n):
            if (adj[u] & (UInt64(1) << v)) != 0 and not seen[v]:
                seen[v] = True; q.append(v)
    if len(order) != n: return -1
    let required = c_size_t(8 * n)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    var bytes = List[UInt8](capacity=Int(required))
    for v in order: put_word(bytes, v)
    for i in range(Int(required)): output[i] = bytes[i]
    return Int64(n)
