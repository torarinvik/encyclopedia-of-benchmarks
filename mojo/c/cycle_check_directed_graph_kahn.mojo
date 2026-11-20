from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cycle_check_directed_graph_kahn")
fn cycle_check_directed_graph_kahn(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 65 or (length - 1) % 2 != 0: return -1
    let n0 = values[0]
    if n0 < 0 or n0 > 64 or (length - 1) / 2 > 32: return -1
    let n = Int(n0)
    var adj = InlineArray[UInt64, 64](fill=0)
    var indegree = InlineArray[Int, 64](fill=0)
    for e in range(Int((length - 1) / 2)):
        let s0 = values[1 + 2 * e]
        let d0 = values[2 + 2 * e]
        if s0 < 0 or d0 < 0 or s0 >= n0 or d0 >= n0: return -1
        let s = Int(s0)
        let d = Int(d0)
        let mask = UInt64(1) << UInt(d)
        if (adj[s] & mask) == 0:
            adj[s] = adj[s] | mask
            indegree[d] += 1
    var queue = InlineArray[Int, 64](fill=0)
    var head = 0
    var tail = 0
    for i in range(n):
        if indegree[i] == 0: queue[tail] = i; tail += 1
    var removed = 0
    while head < tail:
        let s = queue[head]
        head += 1
        removed += 1
        for d in range(n):
            if (adj[s] & (UInt64(1) << UInt(d))) != 0:
                indegree[d] -= 1
                if indegree[d] == 0: queue[tail] = d; tail += 1
    return 0 if removed == n else 1
