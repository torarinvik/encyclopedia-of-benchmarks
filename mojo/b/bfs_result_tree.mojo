from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_i64(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8): bytes.append(UInt8(bits & 255)); bits >>= 8

@export("bfs_result_tree")
fn bfs_result_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let nv = input[0]; let ne = input[1]; let sv = input[2]
    if nv < 1 or nv > 32 or ne < 0 or ne > 126 or sv < 0 or sv >= nv or length != c_size_t(3 + 2 * ne): return -1
    let n = Int(nv); let m = Int(ne); let start = Int(sv)
    var adj = List[List[Int]](capacity=n)
    for _ in range(n): adj.append(List[Int](capacity=n))
    for i in range(m):
        let a = input[3 + 2 * i]; let b = input[4 + 2 * i]
        if a < 0 or a >= nv or b < 0 or b >= nv: return -1
        adj[Int(a)].append(Int(b))
    var seen = List[Bool](capacity=n); var parent = List[Int64](capacity=n); var distance = List[Int64](capacity=n)
    for _ in range(n): seen.append(False); parent.append(-1); distance.append(-1)
    var q = List[Int](capacity=n); var order = List[Int](capacity=n)
    seen[start] = True; distance[start] = 0; q.append(start); var head = 0
    while head < len(q):
        let u = q[head]; head += 1; order.append(u)
        for v in adj[u]:
            if not seen[v]: seen[v] = True; parent[v] = Int64(u); distance[v] = distance[u] + 1; q.append(v)
    var bytes = List[UInt8](capacity=(4 + 6 * len(order)) * 8)
    put_i64(bytes, Int64(len(order)))
    for v in order: put_i64(bytes, Int64(v))
    put_i64(bytes, Int64(len(order)))
    for v in order: put_i64(bytes, Int64(v))
    put_i64(bytes, Int64(len(order)))
    for v in order: put_i64(bytes, Int64(v)); put_i64(bytes, parent[v])
    put_i64(bytes, Int64(len(order)))
    for v in order: put_i64(bytes, Int64(v)); put_i64(bytes, distance[v])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
