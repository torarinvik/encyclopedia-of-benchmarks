from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_INPUT_VALUES = 1 + 3 * (MAX_N - 1)
alias MAX_OUTPUT_VALUES = 2 + MAX_N
alias MATRIX_CELLS = MAX_N * MAX_N
alias MAX_EDGE_WEIGHT = 1_000_000_000

fn td_find_root(mut parent: InlineArray[Int, MAX_N], item: Int) -> Int:
    var node = item
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn td_traverse(n: Int, start: Int, adjacent: InlineArray[Bool, MATRIX_CELLS],
    weights: InlineArray[Int64, MATRIX_CELLS], mut distance: InlineArray[Int64, MAX_N],
    mut path_parent: InlineArray[Int64, MAX_N]):
    var stack = InlineArray[Int, MAX_N]()
    for vertex in range(n):
        distance[vertex] = -1
        path_parent[vertex] = -1
    var top = 1
    stack[0] = start
    distance[start] = 0
    while top > 0:
        top -= 1
        let current = stack[top]
        for neighbor in range(n):
            let cell = current * MAX_N + neighbor
            if adjacent[cell] and distance[neighbor] < 0:
                distance[neighbor] = distance[current] + weights[cell]
                path_parent[neighbor] = Int64(current)
                stack[top] = neighbor
                top += 1

fn td_farthest(n: Int, distance: InlineArray[Int64, MAX_N]) -> Int:
    var best = 0
    for vertex in range(1, n):
        if distance[vertex] > distance[best] or (
            distance[vertex] == distance[best] and vertex < best
        ):
            best = vertex
    return best

fn td_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("tree_diameter")
fn tree_diameter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + 3 * (n - 1)):
        return -1

    var adjacent = InlineArray[Bool, MATRIX_CELLS]()
    var weights = InlineArray[Int64, MATRIX_CELLS]()
    var dsu_parent = InlineArray[Int, MAX_N]()
    var dsu_size = InlineArray[Int, MAX_N]()
    for vertex in range(n):
        dsu_parent[vertex] = vertex
        dsu_size[vertex] = 1
    for edge in range(n - 1):
        let offset = 1 + 3 * edge
        let left_value = input[offset]
        let right_value = input[offset + 1]
        let edge_weight = input[offset + 2]
        if left_value < 0 or left_value >= n_value or right_value < 0 or right_value >= n_value or (
            left_value == right_value or edge_weight < 1 or edge_weight > MAX_EDGE_WEIGHT
        ):
            return -1
        let left = Int(left_value)
        let right = Int(right_value)
        var root_left = td_find_root(mut dsu_parent, left)
        var root_right = td_find_root(mut dsu_parent, right)
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
        weights[left * MAX_N + right] = edge_weight
        weights[right * MAX_N + left] = edge_weight

    var distance = InlineArray[Int64, MAX_N]()
    var path_parent = InlineArray[Int64, MAX_N]()
    td_traverse(n, 0, adjacent, weights, mut distance, mut path_parent)
    let first_endpoint = td_farthest(n, distance)
    td_traverse(n, first_endpoint, adjacent, weights, mut distance, mut path_parent)
    let second_endpoint = td_farthest(n, distance)
    var reverse_path = InlineArray[Int, MAX_N]()
    var path_length = 0
    var current = Int64(second_endpoint)
    while current >= 0:
        reverse_path[path_length] = Int(current)
        path_length += 1
        if Int(current) == first_endpoint:
            break
        current = path_parent[Int(current)]

    var staged = InlineArray[Int64, MAX_OUTPUT_VALUES]()
    var used = 0
    staged[used] = distance[second_endpoint]
    used += 1
    staged[used] = Int64(path_length)
    used += 1
    for position in range(path_length):
        staged[used] = Int64(reverse_path[path_length - 1 - position])
        used += 1
    let required = 8 * used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(used):
        td_store_i64_le(output, 8 * index, staged[index])
    return Int64(required)
