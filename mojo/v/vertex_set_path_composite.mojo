from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 64
comptime MODULUS = 998244353
comptime MAX_INPUT_VALUES = 4 * MAX_N + 4 * MAX_Q

@fieldwise_init
struct Affine(Copyable):
    var a: Int64
    var b: Int64

@fieldwise_init
struct Aggregate(Copyable):
    var forward: Affine
    var backward: Affine

fn identity() -> Affine:
    return Affine(1, 0)

fn compose(after: Affine, before: Affine) -> Affine:
    return Affine(
        (after.a * before.a) % MODULUS,
        (after.a * before.b + after.b) % MODULUS,
    )

fn identity_aggregate() -> Aggregate:
    let id = identity()
    return Aggregate(id, id)

fn combine(left: Aggregate, right: Aggregate) -> Aggregate:
    return Aggregate(
        compose(right.forward, left.forward),
        compose(left.backward, right.backward),
    )

fn find_root(parent: UnsafePointer[Int, MutAnyOrigin], item: Int) -> Int:
    var node = item
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn update_leaf(tree: UnsafePointer[Aggregate, MutAnyOrigin], base: Int,
               position: Int, value: Affine):
    var node = base + position
    tree[node] = Aggregate(value, value)
    while node > 1:
        node //= 2
        tree[node] = combine(tree[node * 2], tree[node * 2 + 1])

fn range_query(tree: UnsafePointer[Aggregate, ImmutAnyOrigin], base: Int,
               left_value: Int, right_value: Int) -> Aggregate:
    var prefix = identity_aggregate()
    var suffix = identity_aggregate()
    var left = left_value + base
    var right = right_value + base
    while left < right:
        if left % 2 == 1:
            prefix = combine(prefix, tree[left])
            left += 1
        if right % 2 == 1:
            right -= 1
            suffix = combine(tree[right], suffix)
        left //= 2
        right //= 2
    return combine(prefix, suffix)

fn path_composition(tree: UnsafePointer[Aggregate, ImmutAnyOrigin], base: Int,
                    parent: UnsafePointer[Int, ImmutAnyOrigin],
                    depth: UnsafePointer[Int, ImmutAnyOrigin],
                    head: UnsafePointer[Int, ImmutAnyOrigin],
                    position: UnsafePointer[Int, ImmutAnyOrigin],
                    from_value: Int, to_value: Int) -> Affine:
    var left = identity()
    var right = identity()
    var from = from_value
    var to = to_value
    while head[from] != head[to]:
        if depth[head[from]] >= depth[head[to]]:
            let part = range_query(tree, base, position[head[from]], position[from] + 1)
            left = compose(part.backward, left)
            from = parent[head[from]]
        else:
            let part = range_query(tree, base, position[head[to]], position[to] + 1)
            right = compose(right, part.forward)
            to = parent[head[to]]
    if depth[from] >= depth[to]:
        let part = range_query(tree, base, position[to], position[from] + 1)
        left = compose(part.backward, left)
    else:
        let part = range_query(tree, base, position[from], position[to] + 1)
        right = compose(right, part.forward)
    return compose(right, left)

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("vertex_set_path_composite")
fn vertex_set_path_composite(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > c_size_t(MAX_INPUT_VALUES):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(4 * n + 4 * q):
        return -1

    var values = InlineArray[Affine, MAX_N](fill=Affine(1, 0))
    for vertex in range(n):
        let a = input[2 + 2 * vertex]
        let b = input[3 + 2 * vertex]
        if a < 1 or a >= MODULUS or b < 0 or b >= MODULUS:
            return -1
        values[vertex] = Affine(a, b)

    var adjacent = InlineArray[Bool, MAX_N * MAX_N](fill=False)
    var dsu_parent = InlineArray[Int, MAX_N](fill=0)
    var dsu_size = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(n):
        dsu_parent[vertex] = vertex
        dsu_size[vertex] = 1
    let edge_start = 2 + 2 * n
    for edge in range(n - 1):
        let offset = edge_start + 2 * edge
        let left_value = input[offset]
        let right_value = input[offset + 1]
        if left_value < 0 or left_value >= n_value or right_value < 0 or right_value >= n_value or left_value == right_value:
            return -1
        let left = Int(left_value)
        let right = Int(right_value)
        var root_left = find_root(dsu_parent.unsafe_ptr(), left)
        var root_right = find_root(dsu_parent.unsafe_ptr(), right)
        if root_left == root_right:
            return -1
        if dsu_size[root_left] < dsu_size[root_right]:
            let temporary = root_left
            root_left = root_right
            root_right = temporary
        dsu_parent[root_right] = root_left
        dsu_size[root_left] += dsu_size[root_right]
        adjacent[left * MAX_N + right] = True
        adjacent[right * MAX_N + left] = True

    let operation_start = edge_start + 2 * (n - 1)
    for query in range(q):
        let offset = operation_start + 4 * query
        let kind = input[offset]
        let first = input[offset + 1]
        let second = input[offset + 2]
        let third = input[offset + 3]
        if kind == 0:
            if first < 0 or first >= n_value or second < 1 or second >= MODULUS or third < 0 or third >= MODULUS:
                return -1
        elif kind == 1:
            if first < 0 or first >= n_value or second < 0 or second >= n_value or third < 0 or third >= MODULUS:
                return -1
        else:
            return -1

    var parent = InlineArray[Int, MAX_N](fill=0)
    var depth = InlineArray[Int, MAX_N](fill=0)
    var subtree = InlineArray[Int, MAX_N](fill=0)
    var heavy = InlineArray[Int, MAX_N](fill=MAX_N)
    var order = InlineArray[Int, MAX_N](fill=0)
    var stack = InlineArray[Int, MAX_N](fill=0)
    var order_count = 1
    var top = 1
    parent[0] = 0
    subtree[0] = 1
    stack[0] = 0
    order[0] = 0
    while top > 0:
        top -= 1
        let vertex = stack[top]
        for neighbor in range(n):
            if not adjacent[vertex * MAX_N + neighbor] or neighbor == parent[vertex]:
                continue
            parent[neighbor] = vertex
            depth[neighbor] = depth[vertex] + 1
            subtree[neighbor] = 1
            heavy[neighbor] = MAX_N
            order[order_count] = neighbor
            order_count += 1
            stack[top] = neighbor
            top += 1
    var reverse_index = order_count
    while reverse_index > 1:
        reverse_index -= 1
        let vertex = order[reverse_index]
        let p = parent[vertex]
        subtree[p] += subtree[vertex]
        if heavy[p] == MAX_N or subtree[vertex] > subtree[heavy[p]] or (subtree[vertex] == subtree[heavy[p]] and vertex < heavy[p]):
            heavy[p] = vertex

    var head = InlineArray[Int, MAX_N](fill=0)
    var position = InlineArray[Int, MAX_N](fill=0)
    var chain_vertex = InlineArray[Int, MAX_N](fill=0)
    var chain_head = InlineArray[Int, MAX_N](fill=0)
    var chain_count = 1
    var timer = 0
    chain_vertex[0] = 0
    chain_head[0] = 0
    while chain_count > 0:
        chain_count -= 1
        var vertex = chain_vertex[chain_count]
        let current_head = chain_head[chain_count]
        while vertex != MAX_N:
            head[vertex] = current_head
            position[vertex] = timer
            timer += 1
            for child in range(n):
                if adjacent[vertex * MAX_N + child] and parent[child] == vertex and child != heavy[vertex]:
                    chain_vertex[chain_count] = child
                    chain_head[chain_count] = child
                    chain_count += 1
            vertex = heavy[vertex]

    var base = 1
    while base < n:
        base *= 2
    var tree = InlineArray[Aggregate, 2 * MAX_N](fill=identity_aggregate())
    for node in range(2 * base):
        tree[node] = identity_aggregate()
    for vertex in range(n):
        update_leaf(tree.unsafe_ptr(), base, position[vertex], values[vertex])

    var answers = InlineArray[Int64, MAX_Q](fill=0)
    var answer_count = 0
    for query in range(q):
        let offset = operation_start + 4 * query
        let kind = input[offset]
        let first = Int(input[offset + 1])
        let second = input[offset + 2]
        let third = input[offset + 3]
        if kind == 0:
            values[first] = Affine(second, third)
            update_leaf(tree.unsafe_ptr(), base, position[first], values[first])
        else:
            let combined = path_composition(
                UnsafePointer[Aggregate, ImmutAnyOrigin](tree.unsafe_ptr()), base,
                UnsafePointer[Int, ImmutAnyOrigin](parent.unsafe_ptr()),
                UnsafePointer[Int, ImmutAnyOrigin](depth.unsafe_ptr()),
                UnsafePointer[Int, ImmutAnyOrigin](head.unsafe_ptr()),
                UnsafePointer[Int, ImmutAnyOrigin](position.unsafe_ptr()), first, Int(second),
            )
            answers[answer_count] = (combined.a * third + combined.b) % MODULUS
            answer_count += 1

    let required = 8 * answer_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(answer_count):
        store_i64_le(output, 8 * index, answers[index])
    return Int64(required)
