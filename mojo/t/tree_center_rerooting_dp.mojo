from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias TC_MAX_N = 64
alias TC_MAX_INPUT_LENGTH = 1 + 2 * (TC_MAX_N - 1)
alias TC_MATRIX_CELLS = TC_MAX_N * TC_MAX_N

fn tc_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("tree_center_rerooting_dp")
fn tree_center_rerooting_dp(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > TC_MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > TC_MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + 2 * (n - 1)):
        return -1

    var adjacency = InlineArray[Int, TC_MATRIX_CELLS]()
    var degree = InlineArray[Int, TC_MAX_N]()
    for edge in range(n - 1):
        let offset = 1 + 2 * edge
        let left_value = input[offset]
        let right_value = input[offset + 1]
        if left_value < 0 or left_value >= n_value or right_value < 0 or right_value >= n_value or left_value == right_value:
            return -1
        let left = Int(left_value)
        let right = Int(right_value)
        adjacency[left * TC_MAX_N + degree[left]] = right
        degree[left] += 1
        adjacency[right * TC_MAX_N + degree[right]] = left
        degree[right] += 1

    var parent = InlineArray[Int, TC_MAX_N]()
    var order = InlineArray[Int, TC_MAX_N]()
    for vertex in range(n):
        parent[vertex] = TC_MAX_N
    parent[0] = TC_MAX_N + 1
    order[0] = 0
    var order_count = 1
    var position = 0
    while position < order_count:
        let vertex = order[position]
        for edge in range(degree[vertex]):
            let child = adjacency[vertex * TC_MAX_N + edge]
            if child == parent[vertex]:
                continue
            if parent[child] != TC_MAX_N:
                return -1
            parent[child] = vertex
            order[order_count] = child
            order_count += 1
        position += 1
    if order_count != n:
        return -1

    var down = InlineArray[Int, TC_MAX_N]()
    var best = InlineArray[Int, TC_MAX_N]()
    var second = InlineArray[Int, TC_MAX_N]()
    var best_child = InlineArray[Int, TC_MAX_N]()
    for vertex in range(n):
        best_child[vertex] = TC_MAX_N
    position = n
    while position > 0:
        position -= 1
        let vertex = order[position]
        for edge in range(degree[vertex]):
            let child = adjacency[vertex * TC_MAX_N + edge]
            if parent[child] != vertex:
                continue
            let branch = down[child] + 1
            if branch > best[vertex]:
                second[vertex] = best[vertex]
                best[vertex] = branch
                best_child[vertex] = child
            elif branch > second[vertex]:
                second[vertex] = branch
        down[vertex] = best[vertex]

    var outside = InlineArray[Int, TC_MAX_N](fill=-1)
    for i in range(n):
        let vertex = order[i]
        for edge in range(degree[vertex]):
            let child = adjacency[vertex * TC_MAX_N + edge]
            if parent[child] != vertex:
                continue
            let sibling = second[vertex] if best_child[vertex] == child else best[vertex]
            let base = outside[vertex] if outside[vertex] > sibling else sibling
            outside[child] = base + 1

    var radius = TC_MAX_N
    for vertex in range(n):
        let eccentricity = down[vertex] if down[vertex] > outside[vertex] else outside[vertex]
        if eccentricity < radius:
            radius = eccentricity
    var centers = InlineArray[Int64, 2]()
    var center_count = 0
    for vertex in range(n):
        let eccentricity = down[vertex] if down[vertex] > outside[vertex] else outside[vertex]
        if eccentricity == radius:
            centers[center_count] = Int64(vertex)
            center_count += 1
    let required = 8 * center_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(center_count):
        tc_store_i64_le(output, 8 * index, centers[index])
    return Int64(required)
