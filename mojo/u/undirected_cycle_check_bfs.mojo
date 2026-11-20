from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("undirected_cycle_check_bfs")
fn undirected_cycle_check_bfs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 514: return -1
    let n0 = input[0]
    let m0 = input[1]
    if n0 < 0 or n0 > 32 or m0 < 0 or m0 > 256: return -1
    let n = Int(n0)
    let m = Int(m0)
    if length != c_size_t(2 + 2 * m): return -1
    var adjacent = InlineArray[Bool, 1024](fill=False)
    var visited = InlineArray[Bool, 32](fill=False)
    for i in range(m):
        let a = input[2 + 2 * i]
        let b = input[3 + 2 * i]
        if a < 0 or b < 0 or a >= n0 or b >= n0: return -1
        let u = Int(a)
        let v = Int(b)
        if adjacent[32 * u + v]: return -1
        adjacent[32 * u + v] = True
        adjacent[32 * v + u] = True
    var queue = InlineArray[Int, 32](fill=0)
    var parent = InlineArray[Int, 32](fill=0)
    for root in range(n):
        if visited[root]: continue
        var head = 0
        var tail = 1
        queue[0] = root
        parent[root] = n
        visited[root] = True
        while head < tail:
            let u = queue[head]
            head += 1
            for v in range(n):
                if not adjacent[32 * u + v]: continue
                if not visited[v]:
                    visited[v] = True
                    parent[v] = u
                    queue[tail] = v
                    tail += 1
                elif v != parent[u]: return 1
    return 0
