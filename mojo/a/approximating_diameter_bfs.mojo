from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("approximating_diameter_bfs")
fn approximating_diameter_bfs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 242: return -1
    let nv = input[0]
    let mv = input[1]
    if nv < 1 or nv > 16 or mv < 0 or mv > 120: return -1
    let n = Int(nv)
    let m = Int(mv)
    if length != c_size_t(2+2*m): return -1
    var adj = List[Bool](capacity=256)
    for _ in range(256): adj.append(False)
    for i in range(m):
        let uv = input[2+2*i]
        let vv = input[3+2*i]
        if uv < 0 or vv <= uv or vv >= nv: return -1
        let u = Int(uv)
        let v = Int(vv)
        if adj[16*u+v]: return -1
        adj[16*u+v] = True
        adj[16*v+u] = True
    var distances = List[Int](capacity=16)
    var queue = List[Int](capacity=16)
    for _ in range(16):
        distances.append(-1)
        queue.append(0)
    distances[0] = 0
    var head = 0
    var tail = 1
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if adj[16*u+v] and distances[v] < 0:
                distances[v] = distances[u]+1
                queue[tail] = v
                tail += 1
    if tail != n: return -1
    var estimate = 0
    for v in range(n): estimate = max(estimate, distances[v])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var bits = UInt64(estimate)
    for j in range(8):
        output[j] = UInt8(bits & UInt64(255))
        bits = bits >> 8
    return 8
