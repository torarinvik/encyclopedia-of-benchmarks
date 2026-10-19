from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_VERTICES = 64
@export("bfs_queue")
fn bfs_queue(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 4096: return -1
    let nv = input[0]; let sv = input[1]; let tv = input[2]; let ne = input[3]
    if nv < 1 or nv > 64 or ne < 0 or ne > 2046 or sv < 0 or sv >= nv or tv < 0 or tv >= nv or length != c_size_t(4 + 2 * ne): return -1
    let n = Int(nv); let m = Int(ne); let start = Int(sv); let goal = Int(tv)
    var adj = List[UInt64](capacity=n); var pred = List[Int](capacity=n); var seen = List[Bool](capacity=n); var q = List[Int](capacity=n)
    for _ in range(n): adj.append(0); pred.append(-1); seen.append(False)
    for i in range(m):
        let a = input[4 + 2 * i]; let b = input[5 + 2 * i]
        if a < 0 or a >= nv or b < 0 or b >= nv: return -1
        adj[Int(a)] |= UInt64(1) << Int(b); adj[Int(b)] |= UInt64(1) << Int(a)
    seen[start] = True; pred[start] = start; q.append(start); var head = 0; var found = start == goal
    while head < len(q) and not found:
        let u = q[head]; head += 1
        for v in range(n):
            if (adj[u] & (UInt64(1) << v)) == 0 or seen[v]: continue
            seen[v] = True; pred[v] = u
            if v == goal: found = True; break
            q.append(v)
    var path = List[UInt8](capacity=n + 1)
    if found:
        var cur = goal
        while cur != start: path.append(UInt8(cur)); cur = pred[cur]
        path.append(UInt8(start))
    let required = len(path) + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    output[0] = UInt8(1 if found else 0)
    for i in range(len(path)): output[i + 1] = path[i]
    return Int64(required)
