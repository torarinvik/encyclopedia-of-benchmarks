from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn directed_dfs(origin: Int64, n: Int64, adj: InlineArray[UInt64, 64], inout state: InlineArray[Int64, 64]) -> Bool:
    var stack = InlineArray[Int64, 64](0)
    var next = InlineArray[Int64, 64](0)
    var top: Int64 = 0
    stack[0] = origin
    state[origin] = 1
    while True:
        let node = stack[top]
        var dest = next[top]
        while dest < n and (adj[node] & (UInt64(1) << dest)) == 0: dest += 1
        if dest == n:
            state[node] = 2
            if top == 0: return False
            top -= 1
        else:
            next[top] = dest + 1
            if state[dest] == 1: return True
            if state[dest] == 0:
                top += 1
                stack[top] = dest
                next[top] = 0
                state[dest] = 1

@export("cycle_check_directed_graph")
fn cycle_check_directed_graph(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 65 or (length - 1) % 2 != 0: return -1
    let n = values[0]
    if n < 0 or n > 64 or (length - 1) / 2 > 32: return -1
    var adj = InlineArray[UInt64, 64](0)
    var state = InlineArray[Int64, 64](0)
    for e in range((length - 1) / 2):
        let s = values[1 + 2 * e]
        let d = values[2 + 2 * e]
        if s < 0 or d < 0 or s >= n or d >= n: return -1
        adj[s] = adj[s] | (UInt64(1) << d)
    for i in range(n):
        if state[i] == 0 and directed_dfs(i, n, adj, state): return 1
    return 0
