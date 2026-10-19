from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("breadth_first_search")
fn breadth_first_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66 or (length - 2) % 2 != 0: return -2
    let nv = input[0]; let startv = input[1]
    if nv < 0 or nv > 64: return -2
    let n = Int(nv); let edges = (Int(length) - 2) // 2
    if n == 0: return 0 if startv == -1 and length == 2 else -2
    if startv < 0 or startv >= nv or edges > 32: return -2
    var adj = List[UInt64](capacity=n); var visited = List[Bool](capacity=n)
    for _ in range(n): adj.append(0); visited.append(False)
    for e in range(edges):
        let u = input[2 + 2 * e]; let v = input[3 + 2 * e]
        if u < 0 or u >= nv or v < 0 or v >= nv: return -2
        adj[Int(u)] = adj[Int(u)] | (UInt64(1) << v)
    var q = List[Int](capacity=n); var result = List[UInt8](capacity=n); q.append(Int(startv)); visited[Int(startv)] = True; var head = 0
    while head < len(q):
        let u = q[head]; head += 1; result.append(UInt8(u))
        for v in range(n):
            if ((adj[u] >> v) & 1) != 0 and not visited[v]: visited[v] = True; q.append(v)
    if len(result) > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(result))): return -2
    for i in range(len(result)): output[i] = result[i]
    return Int64(len(result))
