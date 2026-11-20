from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn connected_without_vertex(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int, removed: Int) -> Bool:
    let start = if removed == 0: 1 else: 0
    var visited = 1 << start
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    queue[0] = start
    var tail = 1
    while head < tail:
        let x = queue[head]
        head += 1
        for e in range(m):
            let u = Int(input[2 + 2 * e])
            let v = Int(input[3 + 2 * e])
            if u == removed or v == removed: continue
            var y = n
            if u == x: y = v
            elif v == x: y = u
            if y < n and (visited & (1 << y)) == 0:
                visited |= 1 << y
                queue[tail] = y
                tail += 1
    return visited == (((1 << n) - 1) & ~(1 << removed))

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs")
fn two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 59: return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 3 or n64 > 8 or m64 < 3 or m64 > 28 or length != c_size_t(2 + 2 * m64): return -1
    let n = Int(n64)
    let m = Int(m64)
    var seen = InlineArray[Bool, 64](fill=False)
    for e in range(m):
        let u = input[2 + 2 * e]
        let v = input[3 + 2 * e]
        if u < 0 or u >= v or v >= n64: return -1
        let key = Int(8 * u + v)
        if seen[key]: return -1
        seen[key] = True
    for removed in range(n):
        if not connected_without_vertex(input, n, m, removed): return -1

    var state = InlineArray[Int, 8](fill=0)
    var disc = InlineArray[Int, 8](fill=0)
    var low = InlineArray[Int, 8](fill=0)
    var low_h = InlineArray[Int, 8](fill=0)
    var savior = InlineArray[Int, 8](fill=0)
    var selected = InlineArray[Bool, 28](fill=False)
    var parent_edge = InlineArray[Int, 8](fill=0)
    var stack_v = InlineArray[Int, 8](fill=0)
    var stack_parent = InlineArray[Int, 8](fill=0)
    var stack_cursor = InlineArray[Int, 8](fill=0)
    var tick = 1
    var top = 1
    state[0] = 1
    disc[0] = 0
    low[0] = 0
    low_h[0] = 0
    savior[0] = 0
    stack_v[0] = 0
    stack_parent[0] = n
    stack_cursor[0] = 0
    while top > 0:
        let frame = top - 1
        let x = stack_v[frame]
        let parent = stack_parent[frame]
        if stack_cursor[frame] < m:
            let e = stack_cursor[frame]
            stack_cursor[frame] += 1
            let u = Int(input[2 + 2 * e])
            let v = Int(input[3 + 2 * e])
            var y = n
            if u == x: y = v
            elif v == x: y = u
            if y == n: continue
            if state[y] == 0:
                selected[e] = True
                parent_edge[y] = e
                state[y] = 1
                disc[y] = tick
                tick += 1
                low[y] = y
                low_h[y] = y
                savior[y] = y
                stack_v[top] = y
                stack_parent[top] = x
                stack_cursor[top] = 0
                top += 1
            elif state[y] == 1 and y != parent and disc[y] < disc[low[x]]:
                low[x] = y
                savior[x] = x
            continue
        state[x] = 2
        if parent < n and low_h[x] == x:
            var a = savior[x]
            var b = low[x]
            if a > b:
                let swap = a
                a = b
                b = swap
            for e in range(m):
                if Int(input[2 + 2 * e]) == a and Int(input[3 + 2 * e]) == b:
                    selected[e] = True
                    break
            low_h[x] = low[x]
        if parent < n and low_h[x] == parent:
            var a = savior[x]
            var b = low[x]
            if a > b:
                let swap = a
                a = b
                b = swap
            for e in range(m):
                if Int(input[2 + 2 * e]) == a and Int(input[3 + 2 * e]) == b:
                    selected[e] = True
                    break
            low_h[x] = low[x]
            if savior[x] == x: selected[parent_edge[x]] = False
        top -= 1
        if parent < n:
            if disc[low[x]] < disc[low[parent]]:
                low[parent] = low[x]
                savior[parent] = savior[x]
            if disc[low_h[x]] < disc[low_h[parent]]:
                low_h[parent] = low_h[x]

    var count = 0
    for e in range(m):
        if selected[e]: count += 1
    let bytes = 8 * (1 + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    store_i64(output, 0, Int64(count))
    var offset = 8
    for a in range(n):
        for b in range(a + 1, n):
            for e in range(m):
                if selected[e] and Int(input[2 + 2 * e]) == a and Int(input[3 + 2 * e]) == b:
                    store_i64(output, offset, Int64(a))
                    store_i64(output, offset + 8, Int64(b))
                    offset += 16
    return Int64(bytes)
