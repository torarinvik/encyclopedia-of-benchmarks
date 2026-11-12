from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 16
alias MAX_Q = 32
alias MAX_EDGES = 15
alias LOG_N = 5

fn root_of(inout parent: InlineArray[Int32, 16], node_arg: Int) -> Int:
    var node = node_arg
    while parent[node] != node:
        parent[node] = parent[Int(parent[node])]
        node = Int(parent[node])
    return node

fn point_set(inout tree: InlineArray[Int64, 64], base: Int, index: Int, value: Int64):
    var position = base + index
    tree[position] = value
    position = position // 2
    while position > 0:
        tree[position] = tree[2 * position] + tree[2 * position + 1]
        position = position // 2

fn range_sum(tree: InlineArray[Int64, 64], base: Int, left: Int, right: Int) -> Int64:
    if left > right:
        return 0
    var l = base + left
    var r = base + right + 1
    var total: Int64 = 0
    while l < r:
        if l & 1 == 1:
            total += tree[l]
            l += 1
        if r & 1 == 1:
            r -= 1
            total += tree[r]
        l = l // 2
        r = r // 2
    return total

fn lca(a_arg: Int, b_arg: Int, depth: InlineArray[Int32, 16], parent: InlineArray[Int32, 16], ancestor: InlineArray[Int32, 80]) -> Int:
    var a = a_arg
    var b = b_arg
    if depth[a] < depth[b]:
        let temp = a
        a = b
        b = temp
    let difference = Int(depth[a] - depth[b])
    for bit in range(LOG_N):
        if ((difference >> bit) & 1) != 0:
            a = Int(ancestor[bit * MAX_N + a])
    if a == b:
        return a
    for reverse in range(LOG_N):
        let bit = LOG_N - 1 - reverse
        if ancestor[bit * MAX_N + a] != ancestor[bit * MAX_N + b]:
            a = Int(ancestor[bit * MAX_N + a])
            b = Int(ancestor[bit * MAX_N + b])
    return Int(parent[a])

@export("tree_edge_paint_path_count")
fn tree_edge_paint_path_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(129):
        return -1
    if input[0] < 1 or input[0] > MAX_N or input[1] < 0 or input[1] > MAX_Q:
        return -1
    let n = Int(input[0])
    let q = Int(input[1])
    let m = n - 1
    if length != c_size_t(2 + 2 * m + 3 * q):
        return -1

    var edge_u = InlineArray[Int32, 15]()
    var edge_v = InlineArray[Int32, 15]()
    var dsu = InlineArray[Int32, 16]()
    for i in range(n):
        dsu[i] = Int32(i)
    var cursor = 2
    for edge in range(m):
        let u_value = input[cursor]
        let v_value = input[cursor + 1]
        cursor += 2
        if u_value < 0 or u_value >= input[0] or v_value < 0 or v_value >= input[0] or u_value == v_value:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        edge_u[edge] = Int32(u)
        edge_v[edge] = Int32(v)
        let ru = root_of(dsu, u)
        let rv = root_of(dsu, v)
        if ru == rv:
            return -1
        dsu[ru] = Int32(rv)
    let tree_root = root_of(dsu, 0)
    for v in range(1, n):
        if root_of(dsu, v) != tree_root:
            return -1

    var parent = InlineArray[Int32, 16]()
    var depth = InlineArray[Int32, 16]()
    var first = InlineArray[Int32, 16]()
    var visited = InlineArray[Bool, 16]()
    var down = InlineArray[Int32, 15]()
    var up = InlineArray[Int32, 15]()
    var stack_node = InlineArray[Int32, 16]()
    var stack_parent = InlineArray[Int32, 16]()
    var stack_in = InlineArray[Int32, 16]()
    var stack_cursor = InlineArray[Int32, 16]()
    stack_parent[0] = -1
    stack_in[0] = -1
    visited[0] = True
    var top = 0
    var occurrences = 0
    while top >= 0:
        let node = Int(stack_node[top])
        var found = False
        while stack_cursor[top] < m:
            let edge = Int(stack_cursor[top])
            stack_cursor[top] += 1
            let eu = Int(edge_u[edge])
            let ev = Int(edge_v[edge])
            if eu != node and ev != node:
                continue
            let child = ev if eu == node else eu
            if child == Int(stack_parent[top]):
                continue
            if visited[child]:
                return -1
            visited[child] = True
            parent[child] = Int32(node)
            depth[child] = depth[node] + 1
            down[edge] = Int32(occurrences)
            occurrences += 1
            first[child] = Int32(occurrences)
            top += 1
            stack_node[top] = Int32(child)
            stack_parent[top] = Int32(node)
            stack_in[top] = Int32(edge)
            stack_cursor[top] = 0
            found = True
            break
        if not found:
            let incoming = Int(stack_in[top])
            top -= 1
            if incoming >= 0:
                up[incoming] = Int32(occurrences)
                occurrences += 1

    var ancestor = InlineArray[Int32, 80]()
    for v in range(n):
        ancestor[v] = parent[v]
    for k in range(1, LOG_N):
        for v in range(n):
            ancestor[k * MAX_N + v] = ancestor[(k - 1) * MAX_N + Int(ancestor[(k - 1) * MAX_N + v])]
    var base = 1
    while base < occurrences:
        base *= 2
    var forward = InlineArray[Int64, 64]()
    var backward = InlineArray[Int64, 64]()
    var painted = InlineArray[Bool, 15]()
    var total: Int64 = 0
    for _ in range(q):
        let kind = input[cursor]
        let a = input[cursor + 1]
        let b = input[cursor + 2]
        cursor += 3
        if kind == 0:
            if a < 0 or a >= Int64(m) or b != 0:
                return -1
            let edge = Int(a)
            if not painted[edge]:
                painted[edge] = True
                point_set(forward, base, Int(down[edge]), 1)
                point_set(backward, base, Int(up[edge]), 1)
        elif kind == 1:
            if a < 0 or a >= Int64(n) or b < 0 or b >= Int64(n):
                return -1
            let common = lca(Int(a), Int(b), depth, parent, ancestor)
            let left_a = Int(first[common])
            let right_a = Int(first[Int(a)]) - 1
            let left_b = Int(first[common])
            let right_b = Int(first[Int(b)]) - 1
            total += range_sum(forward, base, left_a, right_a) - range_sum(backward, base, left_a, right_a)
            total += range_sum(forward, base, left_b, right_b) - range_sum(backward, base, left_b, right_b)
        else:
            return -1
    return total
