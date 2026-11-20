from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("khuller_raghavachari_three_edge_connected_spanning_subgraph")
fn khuller_raghavachari_three_edge_connected_spanning_subgraph(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 59: return -1
    let input_view = input[0:length]
    let n64 = input_view[0]
    let m64 = input_view[1]
    if n64 < 4 or n64 > 8 or m64 < 6 or m64 > 28: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1
    var u = InlineArray[Int, 28](fill=0)
    var v = InlineArray[Int, 28](fill=0)
    for edge in range(m):
        let a64 = input_view[2 + 2 * edge]
        let b64 = input_view[3 + 2 * edge]
        if a64 < 0 or a64 >= b64 or b64 >= n64: return -1
        let a = Int(a64)
        let b = Int(b64)
        for prior in range(edge):
            if u[prior] == a and v[prior] == b: return -1
        u[edge] = a
        v[edge] = b
    let full = (1 << n) - 1
    for side in range(1, full):
        if (side & 1) == 0: continue
        var cut = 0
        for edge in range(m):
            if ((side >> u[edge]) & 1) != ((side >> v[edge]) & 1): cut += 1
        if cut < 3: return -1

    var selected = InlineArray[Bool, 28](fill=False)
    var state = InlineArray[Int, 8](fill=0)
    var discovery = InlineArray[Int, 8](fill=0)
    var finish = InlineArray[Int, 8](fill=0)
    var parent = InlineArray[Int, 8](fill=0)
    var parent_edge = InlineArray[Int, 8](fill=0)
    var postorder = InlineArray[Int, 8](fill=0)
    var stack_vertex = InlineArray[Int, 8](fill=0)
    var stack_slot = InlineArray[Int, 8](fill=0)
    var post_count = 0
    var clock = 1
    var top = 1
    state[0] = 1
    discovery[0] = 0
    parent[0] = n
    parent_edge[0] = m
    stack_vertex[0] = 0
    while top > 0:
        let frame = top - 1
        let x = stack_vertex[frame]
        if stack_slot[frame] < m:
            let edge = stack_slot[frame]
            stack_slot[frame] += 1
            var y = n
            if u[edge] == x: y = v[edge]
            elif v[edge] == x: y = u[edge]
            if y == n or state[y] != 0: continue
            selected[edge] = True
            state[y] = 1
            parent[y] = x
            parent_edge[y] = edge
            discovery[y] = clock
            clock += 1
            stack_vertex[top] = y
            stack_slot[top] = 0
            top += 1
            continue
        state[x] = 2
        finish[x] = clock
        if parent_edge[x] < m:
            postorder[post_count] = parent_edge[x]
            post_count += 1
        top -= 1

    for position in range(post_count):
        let tree_edge = postorder[position]
        let child = parent_edge[u[tree_edge]] == tree_edge ? u[tree_edge] : v[tree_edge]
        let upper = parent[child]
        var separated = False
        for removed in range(m):
            if separated or not selected[removed]: continue
            var seen = InlineArray[Bool, 8](fill=False)
            var queue = InlineArray[Int, 8](fill=0)
            var head = 0
            var tail = 1
            seen[upper] = True
            queue[0] = upper
            while head < tail:
                let current = queue[head]
                head += 1
                for edge in range(m):
                    if not selected[edge] or edge == removed: continue
                    var next = n
                    if u[edge] == current: next = v[edge]
                    elif v[edge] == current: next = u[edge]
                    if next < n and not seen[next]:
                        seen[next] = True
                        queue[tail] = next
                        tail += 1
            if not seen[child]: separated = True
        if not separated: continue
        var candidate = m
        var earliest = n
        for edge in range(m):
            if selected[edge]: continue
            let u_inside = discovery[child] <= discovery[u[edge]] and discovery[u[edge]] < finish[child]
            let v_inside = discovery[child] <= discovery[v[edge]] and discovery[v[edge]] < finish[child]
            if u_inside == v_inside: continue
            let ancestor = u_inside ? v[edge] : u[edge]
            if discovery[ancestor] < earliest:
                earliest = discovery[ancestor]
                candidate = edge
        if candidate == m: return -1
        selected[candidate] = True

    var leader = InlineArray[Int, 8](fill=0)
    for vertex in range(n): leader[vertex] = vertex
    for edge in range(m):
        if selected[edge]: continue
        var a = u[edge]
        var b = v[edge]
        while leader[a] != a:
            leader[a] = leader[leader[a]]
            a = leader[a]
        while leader[b] != b:
            leader[b] = leader[leader[b]]
            b = leader[b]
        if a != b:
            leader[b] = a
            selected[edge] = True
    var count = 0
    for edge in range(m):
        if selected[edge]: count += 1
    let bytes = 8 * (1 + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    store_i64(output, 0, Int64(count))
    var slot = 0
    for edge in range(m):
        if not selected[edge]: continue
        store_i64(output, 8 * (1 + 2 * slot), Int64(u[edge]))
        store_i64(output, 8 * (2 + 2 * slot), Int64(v[edge]))
        slot += 1
    return Int64(bytes)
