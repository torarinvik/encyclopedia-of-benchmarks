from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_Q = 64
alias MAX_LEVELS = 7
alias MAX_INPUT_VALUES = 2 + 2 * (MAX_N - 1) + 3 * MAX_Q

fn jot_find_root(mut parent: InlineArray[Int, MAX_N], item: Int) -> Int:
    var node = item
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn jot_lift(ancestors: InlineArray[Int, MAX_N * MAX_LEVELS],
    vertex_value: Int, distance: Int) -> Int:
    var vertex = vertex_value
    for bit in range(MAX_LEVELS):
        if ((distance >> bit) & 1) != 0:
            vertex = ancestors[vertex * MAX_LEVELS + bit]
    return vertex

fn jot_lca(ancestors: InlineArray[Int, MAX_N * MAX_LEVELS],
    depth: InlineArray[Int, MAX_N], left_value: Int, right_value: Int) -> Int:
    var left = left_value
    var right = right_value
    if depth[left] < depth[right]:
        let temporary = left
        left = right
        right = temporary
    left = jot_lift(ancestors, left, depth[left] - depth[right])
    if left == right:
        return left
    var level = MAX_LEVELS
    while level > 0:
        level -= 1
        if ancestors[left * MAX_LEVELS + level] != ancestors[right * MAX_LEVELS + level]:
            left = ancestors[left * MAX_LEVELS + level]
            right = ancestors[right * MAX_LEVELS + level]
    return ancestors[left * MAX_LEVELS]

fn jot_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("jump_on_tree")
fn jump_on_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 2 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    let query_start = 2 + 2 * (n - 1)
    if length != c_size_t(query_start + 3 * q):
        return -1

    var adjacent = InlineArray[Bool, MAX_N * MAX_N]()
    var dsu_parent = InlineArray[Int, MAX_N]()
    var dsu_size = InlineArray[Int, MAX_N]()
    for vertex in range(n):
        dsu_parent[vertex] = vertex
        dsu_size[vertex] = 1
    for edge in range(n - 1):
        let offset = 2 + 2 * edge
        let left_value = input[offset]
        let right_value = input[offset + 1]
        if left_value < 0 or left_value >= n_value or right_value < 0 or (
            right_value >= n_value or left_value == right_value
        ):
            return -1
        let left = Int(left_value)
        let right = Int(right_value)
        var root_left = jot_find_root(mut dsu_parent, left)
        var root_right = jot_find_root(mut dsu_parent, right)
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

    var ancestors = InlineArray[Int, MAX_N * MAX_LEVELS]()
    var depth = InlineArray[Int, MAX_N]()
    var visited = InlineArray[Bool, MAX_N]()
    var stack = InlineArray[Int, MAX_N]()
    var top = 1
    stack[0] = 0
    visited[0] = True
    while top > 0:
        top -= 1
        let vertex = stack[top]
        for neighbor in range(n):
            if not adjacent[vertex * MAX_N + neighbor] or visited[neighbor]:
                continue
            visited[neighbor] = True
            ancestors[neighbor * MAX_LEVELS] = vertex
            depth[neighbor] = depth[vertex] + 1
            stack[top] = neighbor
            top += 1
    for level in range(1, MAX_LEVELS):
        for vertex in range(n):
            let middle = ancestors[vertex * MAX_LEVELS + level - 1]
            ancestors[vertex * MAX_LEVELS + level] = ancestors[middle * MAX_LEVELS + level - 1]

    var answers = InlineArray[Int64, MAX_Q]()
    for query in range(q):
        let offset = query_start + 3 * query
        let start_value = input[offset]
        let target_value = input[offset + 1]
        let index_value = input[offset + 2]
        if start_value < 0 or start_value >= n_value or target_value < 0 or (
            target_value >= n_value or index_value < 0 or index_value >= n_value
        ):
            return -1
        let start = Int(start_value)
        let target = Int(target_value)
        let index = Int(index_value)
        let common = jot_lca(ancestors, depth, start, target)
        let upward = depth[start] - depth[common]
        let path_length = upward + depth[target] - depth[common]
        if index > path_length:
            answers[query] = -1
        elif index <= upward:
            answers[query] = Int64(jot_lift(ancestors, start, index))
        else:
            answers[query] = Int64(jot_lift(ancestors, target, path_length - index))

    let required = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for query in range(q):
        jot_store_i64_le(output, 8 * query, answers[query])
    return Int64(required)
