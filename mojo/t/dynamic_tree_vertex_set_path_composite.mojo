from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime DTVPC_MAX_N = 8
comptime DTVPC_MAX_Q = 12
comptime DTVPC_MAX_INPUT = 93
comptime DTVPC_MODULUS: Int64 = 998244353
comptime DTVPC_NODE_FIELDS = 10

fn dtvpc_identity_a() -> Int64:
    return 1

fn dtvpc_compose_a(after_a: Int64, after_b: Int64, before_a: Int64, before_b: Int64) -> InlineArray[Int64, 2]:
    var result = InlineArray[Int64, 2]()
    result[0] = after_a * before_a % DTVPC_MODULUS
    result[1] = (after_a * before_b + after_b) % DTVPC_MODULUS
    return result

fn dtvpc_is_aux_root(nodes: InlineArray[Int64, 80], x: Int) -> Bool:
    let parent = nodes[DTVPC_NODE_FIELDS * 2 + x]
    if parent < 0: return True
    let p = Int(parent)
    return nodes[p] != Int64(x) and nodes[DTVPC_MAX_N + p] != Int64(x)

fn dtvpc_pull(inout nodes: InlineArray[Int64, 80], x: Int):
    let left = Int(nodes[x])
    let right = Int(nodes[DTVPC_MAX_N + x])
    var left_forward_a: Int64 = 1
    var left_forward_b: Int64 = 0
    var right_forward_a: Int64 = 1
    var right_forward_b: Int64 = 0
    var left_backward_a: Int64 = 1
    var left_backward_b: Int64 = 0
    var right_backward_a: Int64 = 1
    var right_backward_b: Int64 = 0
    if left >= 0:
        left_forward_a = nodes[6 * DTVPC_MAX_N + left]
        left_forward_b = nodes[7 * DTVPC_MAX_N + left]
        left_backward_a = nodes[8 * DTVPC_MAX_N + left]
        left_backward_b = nodes[9 * DTVPC_MAX_N + left]
    if right >= 0:
        right_forward_a = nodes[6 * DTVPC_MAX_N + right]
        right_forward_b = nodes[7 * DTVPC_MAX_N + right]
        right_backward_a = nodes[8 * DTVPC_MAX_N + right]
        right_backward_b = nodes[9 * DTVPC_MAX_N + right]
    let value_a = nodes[4 * DTVPC_MAX_N + x]
    let value_b = nodes[5 * DTVPC_MAX_N + x]
    let inner_forward = dtvpc_compose_a(value_a, value_b, left_forward_a, left_forward_b)
    let forward = dtvpc_compose_a(right_forward_a, right_forward_b, inner_forward[0], inner_forward[1])
    let inner_backward = dtvpc_compose_a(value_a, value_b, right_backward_a, right_backward_b)
    let backward = dtvpc_compose_a(left_backward_a, left_backward_b, inner_backward[0], inner_backward[1])
    nodes[6 * DTVPC_MAX_N + x] = forward[0]
    nodes[7 * DTVPC_MAX_N + x] = forward[1]
    nodes[8 * DTVPC_MAX_N + x] = backward[0]
    nodes[9 * DTVPC_MAX_N + x] = backward[1]

fn dtvpc_reverse(inout nodes: InlineArray[Int64, 80], x_value: Int64):
    if x_value < 0: return
    let x = Int(x_value)
    let child = nodes[x]
    nodes[x] = nodes[DTVPC_MAX_N + x]
    nodes[DTVPC_MAX_N + x] = child
    let forward_a = nodes[6 * DTVPC_MAX_N + x]
    let forward_b = nodes[7 * DTVPC_MAX_N + x]
    nodes[6 * DTVPC_MAX_N + x] = nodes[8 * DTVPC_MAX_N + x]
    nodes[7 * DTVPC_MAX_N + x] = nodes[9 * DTVPC_MAX_N + x]
    nodes[8 * DTVPC_MAX_N + x] = forward_a
    nodes[9 * DTVPC_MAX_N + x] = forward_b
    nodes[3 * DTVPC_MAX_N + x] = 1 - nodes[3 * DTVPC_MAX_N + x]

fn dtvpc_push(inout nodes: InlineArray[Int64, 80], x: Int):
    if nodes[3 * DTVPC_MAX_N + x] == 0: return
    dtvpc_reverse(nodes, nodes[x])
    dtvpc_reverse(nodes, nodes[DTVPC_MAX_N + x])
    nodes[3 * DTVPC_MAX_N + x] = 0

fn dtvpc_rotate(inout nodes: InlineArray[Int64, 80], x: Int):
    let p = Int(nodes[2 * DTVPC_MAX_N + x])
    let g = nodes[2 * DTVPC_MAX_N + p]
    let is_right = nodes[DTVPC_MAX_N + p] == Int64(x)
    var middle: Int64 = nodes[DTVPC_MAX_N + x]
    if is_right: middle = nodes[x]
    if not dtvpc_is_aux_root(nodes, p):
        let gi = Int(g)
        if nodes[gi] == Int64(p): nodes[gi] = Int64(x)
        else: nodes[DTVPC_MAX_N + gi] = Int64(x)
    nodes[2 * DTVPC_MAX_N + x] = g
    if is_right:
        nodes[x] = Int64(p)
        nodes[DTVPC_MAX_N + p] = middle
    else:
        nodes[DTVPC_MAX_N + x] = Int64(p)
        nodes[x] = middle
    nodes[2 * DTVPC_MAX_N + p] = Int64(x)
    if middle >= 0: nodes[2 * DTVPC_MAX_N + Int(middle)] = Int64(p)
    dtvpc_pull(nodes, p)
    dtvpc_pull(nodes, x)

fn dtvpc_splay(inout nodes: InlineArray[Int64, 80], x: Int):
    var stack = InlineArray[Int, DTVPC_MAX_N]()
    var count = 1
    var y = x
    stack[0] = y
    while not dtvpc_is_aux_root(nodes, y):
        y = Int(nodes[2 * DTVPC_MAX_N + y])
        stack[count] = y
        count += 1
    while count > 0:
        count -= 1
        dtvpc_push(nodes, stack[count])
    while not dtvpc_is_aux_root(nodes, x):
        let p = Int(nodes[2 * DTVPC_MAX_N + x])
        if not dtvpc_is_aux_root(nodes, p):
            let g = Int(nodes[2 * DTVPC_MAX_N + p])
            let zigzig = (nodes[p] == Int64(x)) == (nodes[g] == Int64(p))
            if zigzig: dtvpc_rotate(nodes, p)
            else: dtvpc_rotate(nodes, x)
        dtvpc_rotate(nodes, x)

fn dtvpc_access(inout nodes: InlineArray[Int64, 80], x: Int):
    var last: Int64 = -1
    var y: Int64 = Int64(x)
    while y >= 0:
        let index = Int(y)
        dtvpc_splay(nodes, index)
        nodes[DTVPC_MAX_N + index] = last
        if last >= 0: nodes[2 * DTVPC_MAX_N + Int(last)] = y
        dtvpc_pull(nodes, index)
        last = y
        y = nodes[2 * DTVPC_MAX_N + index]
    dtvpc_splay(nodes, x)

fn dtvpc_make_root(inout nodes: InlineArray[Int64, 80], x: Int):
    dtvpc_access(nodes, x)
    dtvpc_reverse(nodes, Int64(x))

fn dtvpc_find_root(inout nodes: InlineArray[Int64, 80], x: Int) -> Int:
    dtvpc_access(nodes, x)
    dtvpc_push(nodes, x)
    var root = x
    while nodes[root] >= 0:
        root = Int(nodes[root])
        dtvpc_push(nodes, root)
    dtvpc_splay(nodes, root)
    return root

fn dtvpc_link(inout nodes: InlineArray[Int64, 80], u: Int, v: Int) -> Bool:
    if u == v: return False
    dtvpc_make_root(nodes, u)
    if dtvpc_find_root(nodes, v) == u: return False
    nodes[2 * DTVPC_MAX_N + u] = Int64(v)
    return True

fn dtvpc_cut(inout nodes: InlineArray[Int64, 80], u: Int, v: Int) -> Bool:
    if u == v: return False
    dtvpc_make_root(nodes, u)
    dtvpc_access(nodes, v)
    if nodes[v] != Int64(u) or nodes[DTVPC_MAX_N + u] >= 0: return False
    nodes[v] = -1
    nodes[2 * DTVPC_MAX_N + u] = -1
    dtvpc_pull(nodes, v)
    return True

fn dtvpc_set_value(inout nodes: InlineArray[Int64, 80], vertex: Int, multiplier: Int64, addend: Int64):
    dtvpc_access(nodes, vertex)
    nodes[4 * DTVPC_MAX_N + vertex] = multiplier
    nodes[5 * DTVPC_MAX_N + vertex] = addend
    dtvpc_pull(nodes, vertex)

fn dtvpc_path(inout nodes: InlineArray[Int64, 80], u: Int, v: Int) -> InlineArray[Int64, 2]:
    var result = InlineArray[Int64, 2]()
    dtvpc_make_root(nodes, u)
    if dtvpc_find_root(nodes, v) != u:
        result[0] = -1
        return result
    dtvpc_make_root(nodes, u)
    dtvpc_access(nodes, v)
    result[0] = nodes[6 * DTVPC_MAX_N + v]
    result[1] = nodes[7 * DTVPC_MAX_N + v]
    return result

fn dtvpc_find_dsu(inout parent: InlineArray[Int, DTVPC_MAX_N], item: Int) -> Int:
    var node = item
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn dtvpc_connected(adjacency: InlineArray[Bool, 64], n: Int, start: Int, target: Int) -> Bool:
    var seen = InlineArray[Bool, DTVPC_MAX_N]()
    var stack = InlineArray[Int, DTVPC_MAX_N]()
    var top = 1
    seen[start] = True
    stack[0] = start
    while top > 0:
        top -= 1
        let u = stack[top]
        if u == target: return True
        for v in range(n):
            let cell = u * DTVPC_MAX_N + v
            if adjacency[cell] and not seen[v]:
                seen[v] = True
                stack[top] = v
                top += 1
    return False

fn dtvpc_store_i64_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("dynamic_tree_vertex_set_path_composite")
fn dynamic_tree_vertex_set_path_composite(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > DTVPC_MAX_INPUT:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > DTVPC_MAX_N or q_value < 1 or q_value > DTVPC_MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if Int(length) < 2 + 2 * n + 2 * (n - 1) + 4 * q:
        return -1

    var values = InlineArray[Int64, 16]()
    for vertex in range(n):
        let multiplier = input[2 + 2 * vertex]
        let addend = input[3 + 2 * vertex]
        if multiplier < 1 or multiplier >= DTVPC_MODULUS or addend < 0 or addend >= DTVPC_MODULUS:
            return -1
        values[2 * vertex] = multiplier
        values[2 * vertex + 1] = addend

    var adjacency = InlineArray[Bool, 64]()
    var dsu = InlineArray[Int, DTVPC_MAX_N]()
    var edge_u = InlineArray[Int, DTVPC_MAX_N]()
    var edge_v = InlineArray[Int, DTVPC_MAX_N]()
    for vertex in range(n): dsu[vertex] = vertex
    var cursor = 2 + 2 * n
    for edge in range(n - 1):
        let u_value = input[cursor]
        let v_value = input[cursor + 1]
        cursor += 2
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        let root_u = dtvpc_find_dsu(dsu, u)
        let root_v = dtvpc_find_dsu(dsu, v)
        if root_u == root_v: return -1
        dsu[root_v] = root_u
        adjacency[u * DTVPC_MAX_N + v] = True
        adjacency[v * DTVPC_MAX_N + u] = True
        edge_u[edge] = u
        edge_v[edge] = v

    var queries = InlineArray[Int64, 60]()
    var answer_count = 0
    for query in range(q):
        if cursor >= Int(length): return -1
        let kind = input[cursor]
        queries[5 * query] = kind
        cursor += 1
        var width = 0
        if kind == 0: width = 4
        elif kind == 1 or kind == 2: width = 3
        else: return -1
        if Int(length) - cursor < width: return -1
        for field in range(width): queries[5 * query + 1 + field] = input[cursor + field]
        cursor += width
        let a = queries[5 * query + 1]
        let b = queries[5 * query + 2]
        let c = queries[5 * query + 3]
        if kind == 0:
            let d = queries[5 * query + 4]
            if a < 0 or a >= n_value or b < 0 or b >= n_value or c < 0 or c >= n_value or d < 0 or d >= n_value or a == b or c == d:
                return -1
            let u = Int(a); let v = Int(b); let w = Int(c); let x = Int(d)
            if not adjacency[u * DTVPC_MAX_N + v]: return -1
            adjacency[u * DTVPC_MAX_N + v] = False
            adjacency[v * DTVPC_MAX_N + u] = False
            if dtvpc_connected(adjacency, n, w, x): return -1
            adjacency[w * DTVPC_MAX_N + x] = True
            adjacency[x * DTVPC_MAX_N + w] = True
        elif kind == 1:
            if a < 0 or a >= n_value or b < 1 or b >= DTVPC_MODULUS or c < 0 or c >= DTVPC_MODULUS:
                return -1
        else:
            if a < 0 or a >= n_value or b < 0 or b >= n_value or c < 0 or c >= DTVPC_MODULUS:
                return -1
            answer_count += 1
    if cursor != Int(length): return -1

    let required = 8 * answer_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var nodes = InlineArray[Int64, 80]()
    for vertex in range(DTVPC_MAX_N):
        nodes[vertex] = -1
        nodes[DTVPC_MAX_N + vertex] = -1
        nodes[2 * DTVPC_MAX_N + vertex] = -1
    for vertex in range(n):
        nodes[4 * DTVPC_MAX_N + vertex] = values[2 * vertex]
        nodes[5 * DTVPC_MAX_N + vertex] = values[2 * vertex + 1]
        nodes[6 * DTVPC_MAX_N + vertex] = values[2 * vertex]
        nodes[7 * DTVPC_MAX_N + vertex] = values[2 * vertex + 1]
        nodes[8 * DTVPC_MAX_N + vertex] = values[2 * vertex]
        nodes[9 * DTVPC_MAX_N + vertex] = values[2 * vertex + 1]
    for edge in range(n - 1):
        if not dtvpc_link(nodes, edge_u[edge], edge_v[edge]): return -1

    var answers = InlineArray[Int64, DTVPC_MAX_Q]()
    var written = 0
    for query in range(q):
        let kind = queries[5 * query]
        let a = Int(queries[5 * query + 1])
        let b = Int(queries[5 * query + 2])
        let c = queries[5 * query + 3]
        if kind == 0:
            let d = Int(queries[5 * query + 4])
            if not dtvpc_cut(nodes, a, b) or not dtvpc_link(nodes, Int(c), d): return -1
        elif kind == 1:
            dtvpc_set_value(nodes, a, b, c)
        else:
            let combined = dtvpc_path(nodes, a, b)
            if combined[0] < 0: return -1
            answers[written] = (combined[0] * c + combined[1]) % DTVPC_MODULUS
            written += 1
    for i in range(written): dtvpc_store_i64_le(answers[i], output, 8 * i)
    return Int64(required)
