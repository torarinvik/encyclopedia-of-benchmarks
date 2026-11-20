from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_N = 64
comptime MAX_Q = 64
comptime MAX_INPUT = 320
comptime MAX_WEIGHT = Int64(1_000_000)
comptime NEG = Int64(-1_152_921_504_606_846_976)

struct Matrix(Copyable):
    var a00: Int64
    var a01: Int64
    var a10: Int64
    var a11: Int64

fn identity() -> Matrix:
    return Matrix(0, NEG, NEG, 0)

fn maximum(a: Int64, b: Int64) -> Int64:
    if a > b: return a
    return b

fn multiply(a: Matrix, b: Matrix) -> Matrix:
    let c00 = maximum(a.a00 + b.a00, a.a01 + b.a10)
    let c01 = maximum(a.a00 + b.a01, a.a01 + b.a11)
    let c10 = maximum(a.a10 + b.a00, a.a11 + b.a10)
    let c11 = maximum(a.a10 + b.a01, a.a11 + b.a11)
    return Matrix(c00, c01, c10, c11)

fn find_root(mut parent: InlineArray[Int, MAX_N], vertex: Int) -> Int:
    var v = vertex
    while parent[v] != v:
        parent[v] = parent[parent[v]]
        v = parent[v]
    return v

fn set_matrix(mut tree: InlineArray[Matrix, MAX_N * 2], position: Int, value: Matrix) -> None:
    var node = MAX_N + position
    tree[node] = value
    node /= 2
    while node > 0:
        tree[node] = multiply(tree[node * 2], tree[node * 2 + 1])
        node /= 2

fn query(tree: InlineArray[Matrix, MAX_N * 2], left: Int, right: Int) -> Matrix:
    var l = MAX_N + left
    var r = MAX_N + right
    var before = identity()
    var after = identity()
    while l < r:
        if l % 2 == 1:
            before = multiply(before, tree[l])
            l += 1
        if r % 2 == 1:
            r -= 1
            after = multiply(tree[r], after)
        l /= 2
        r /= 2
    return multiply(before, after)

fn summary(tree: InlineArray[Matrix, MAX_N * 2], position: InlineArray[Int, MAX_N],
           tail: InlineArray[Int, MAX_N], h: Int) -> InlineArray[Int64, 2]:
    let product = query(tree, position[h], position[tail[h]] + 1)
    var result = InlineArray[Int64, 2]()
    result[0] = maximum(product.a00, product.a01)
    result[1] = maximum(product.a10, product.a11)
    return result

fn store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("dynamic_tree_maximum_weight_independent_set")
fn dynamic_tree_maximum_weight_independent_set(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let nn = input[0]
    let qq = input[1]
    if nn < 1 or nn > MAX_N or qq < 0 or qq > MAX_Q: return -1
    let n = Int(nn)
    let q = Int(qq)
    let edge_end = 2 + n + 2 * (n - 1)
    if length != c_size_t(edge_end + 2 * q): return -1

    var dsu = InlineArray[Int, MAX_N]()
    var weights = InlineArray[Int64, MAX_N]()
    var adjacency = InlineArray[Bool, MAX_N * MAX_N]()
    for u in range(n):
        dsu[u] = u
        weights[u] = input[2 + u]
        if weights[u] < 0 or weights[u] > MAX_WEIGHT: return -1
    for edge in range(n - 1):
        let offset = 2 + n + 2 * edge
        let uu = input[offset]
        let vv = input[offset + 1]
        if uu < 0 or uu >= nn or vv < 0 or vv >= nn or uu == vv: return -1
        let u = Int(uu)
        let v = Int(vv)
        let ru = find_root(mut dsu, u)
        let rv = find_root(mut dsu, v)
        if ru == rv: return -1
        dsu[ru] = rv
        adjacency[u * MAX_N + v] = True
        adjacency[v * MAX_N + u] = True
    let root_set = find_root(mut dsu, 0)
    for v in range(1, n):
        if find_root(mut dsu, v) != root_set: return -1

    var update_vertex = InlineArray[Int, MAX_Q]()
    var update_weight = InlineArray[Int64, MAX_Q]()
    for i in range(q):
        let offset = edge_end + 2 * i
        let vertex = input[offset]
        let weight = input[offset + 1]
        if vertex < 0 or vertex >= nn or weight < 0 or weight > MAX_WEIGHT: return -1
        update_vertex[i] = Int(vertex)
        update_weight[i] = weight
    let output_bytes = 8 * q
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)): return -2
    if q == 0: return 0

    var parent = InlineArray[Int, MAX_N]()
    for v in range(n): parent[v] = -2
    parent[0] = -1
    var order = InlineArray[Int, MAX_N]()
    order[0] = 0
    var order_count = 1
    var cursor = 0
    while cursor < order_count:
        let u = order[cursor]
        cursor += 1
        for v in range(n):
            if adjacency[u * MAX_N + v] and parent[v] == -2:
                parent[v] = u
                order[order_count] = v
                order_count += 1

    var subtree = InlineArray[Int, MAX_N]()
    var heavy = InlineArray[Int, MAX_N]()
    var skip = InlineArray[Int64, MAX_N]()
    var take = InlineArray[Int64, MAX_N]()
    for u in range(n):
        subtree[u] = 1
        heavy[u] = -1
        take[u] = weights[u]
    var index = n
    while index > 1:
        index -= 1
        let u = order[index]
        let p = parent[u]
        subtree[p] += subtree[u]
        if heavy[p] < 0 or subtree[u] > subtree[heavy[p]]: heavy[p] = u
        skip[p] += maximum(skip[u], take[u])
        take[p] += skip[u]

    var head = InlineArray[Int, MAX_N]()
    var position = InlineArray[Int, MAX_N]()
    var tail = InlineArray[Int, MAX_N]()
    var chain_stack = InlineArray[Int, MAX_N]()
    chain_stack[0] = 0
    var chain_count = 1
    var clock = 0
    while chain_count > 0:
        chain_count -= 1
        let h = chain_stack[chain_count]
        var u = h
        while u >= 0:
            head[u] = h
            position[u] = clock
            clock += 1
            tail[h] = u
            for v in range(1, n):
                if parent[v] == u and v != heavy[u]:
                    chain_stack[chain_count] = v
                    chain_count += 1
            u = heavy[u]

    var matrices = InlineArray[Matrix, MAX_N]()
    var segment = InlineArray[Matrix, MAX_N * 2]()
    for i in range(MAX_N * 2): segment[i] = identity()
    for u in range(n):
        var light0 = Int64(0)
        var light1 = weights[u]
        for v in range(1, n):
            if parent[v] == u and v != heavy[u]:
                light0 += maximum(skip[v], take[v])
                light1 += skip[v]
        matrices[u] = Matrix(light0, light0, light1, NEG)
        segment[MAX_N + position[u]] = matrices[u]
    var build = MAX_N
    while build > 1:
        build -= 1
        segment[build] = multiply(segment[2 * build], segment[2 * build + 1])

    var staged = InlineArray[Int64, MAX_Q]()
    for i in range(q):
        let vertex = update_vertex[i]
        var h = head[vertex]
        var old_state = summary(segment, position, tail, h)
        let delta = update_weight[i] - weights[vertex]
        weights[vertex] = update_weight[i]
        matrices[vertex].a10 += delta
        set_matrix(mut segment, position[vertex], matrices[vertex])
        var new_state = summary(segment, position, tail, h)
        while parent[h] != -1:
            let p = parent[h]
            let ph = head[p]
            let before = summary(segment, position, tail, ph)
            let delta0 = maximum(new_state[0], new_state[1]) - maximum(old_state[0], old_state[1])
            let delta1 = new_state[0] - old_state[0]
            matrices[p].a00 += delta0
            matrices[p].a01 += delta0
            matrices[p].a10 += delta1
            set_matrix(mut segment, position[p], matrices[p])
            old_state = before
            new_state = summary(segment, position, tail, ph)
            h = ph
        let answer = summary(segment, position, tail, 0)
        staged[i] = maximum(answer[0], answer[1])
    for i in range(q): store_le(output, 8 * i, staged[i])
    return Int64(output_bytes)
