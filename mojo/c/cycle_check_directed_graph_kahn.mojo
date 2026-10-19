from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cycle_check_directed_graph_kahn")
fn cycle_check_directed_graph_kahn(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 65 or (length - 1) % 2 != 0: return -1
    let n = values[0]
    if n < 0 or n > 64 or (length - 1) / 2 > 32: return -1
    var adj = InlineArray[UInt64, 64](0)
    var indegree = InlineArray[Int64, 64](0)
    for e in range((length - 1) / 2):
        let s = values[1 + 2 * e]
        let d = values[2 + 2 * e]
        if s < 0 or d < 0 or s >= n or d >= n: return -1
        let mask = UInt64(1) << d
        if (adj[s] & mask) == 0:
            adj[s] = adj[s] | mask
            indegree[d] += 1
    var queue = InlineArray[Int64, 64](0)
    var head: Int64 = 0
    var tail: Int64 = 0
    for i in range(n):
        if indegree[i] == 0: queue[tail] = i; tail += 1
    var removed: Int64 = 0
    while head < tail:
        let s = queue[head]
        head += 1
        removed += 1
        for d in range(n):
            if (adj[s] & (UInt64(1) << d)) != 0:
                indegree[d] -= 1
                if indegree[d] == 0: queue[tail] = d; tail += 1
    return 0 if removed == n else 1
