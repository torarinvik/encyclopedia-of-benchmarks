from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_INPUT_LENGTH = 1 + 2 * (MAX_N - 1)
alias MATRIX_CELLS = MAX_N * MAX_N

fn tc_find_root(mut parent: InlineArray[Int, MAX_N], item: Int) -> Int:
    var node = item
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn tc_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("tree_center")
fn tree_center(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + 2 * (n - 1)):
        return -1

    var adjacency = InlineArray[Int, MATRIX_CELLS]()
    var adjacency_count = InlineArray[Int, MAX_N]()
    var degree = InlineArray[Int, MAX_N]()
    var parent = InlineArray[Int, MAX_N]()
    var component_size = InlineArray[Int, MAX_N]()
    for vertex in range(n):
        parent[vertex] = vertex
        component_size[vertex] = 1
    for edge in range(n - 1):
        let offset = 1 + 2 * edge
        let left_value = input[offset]
        let right_value = input[offset + 1]
        if left_value < 0 or left_value >= n_value or right_value < 0 or right_value >= n_value or left_value == right_value:
            return -1
        let left = Int(left_value)
        let right = Int(right_value)
        var root_left = tc_find_root(mut parent, left)
        var root_right = tc_find_root(mut parent, right)
        if root_left == root_right:
            return -1
        if component_size[root_left] < component_size[root_right]:
            let temporary = root_left
            root_left = root_right
            root_right = temporary
        parent[root_right] = root_left
        component_size[root_left] += component_size[root_right]
        adjacency[left * MAX_N + adjacency_count[left]] = right
        adjacency_count[left] += 1
        adjacency[right * MAX_N + adjacency_count[right]] = left
        adjacency_count[right] += 1
        degree[left] += 1
        degree[right] += 1
    if n > 1 and component_size[tc_find_root(mut parent, 0)] != n:
        return -1

    var active = InlineArray[Bool, MAX_N](fill=False)
    var leaves = InlineArray[Int, MAX_N]()
    var leaf_count = 0
    for vertex in range(n):
        active[vertex] = True
        if degree[vertex] <= 1:
            leaves[leaf_count] = vertex
            leaf_count += 1
    var remaining = n
    while remaining > 2:
        for index in range(leaf_count):
            active[leaves[index]] = False
        remaining -= leaf_count
        for index in range(leaf_count):
            let leaf = leaves[index]
            for edge in range(adjacency_count[leaf]):
                let neighbor = adjacency[leaf * MAX_N + edge]
                if active[neighbor]:
                    degree[neighbor] -= 1
        if remaining <= 2:
            break
        leaf_count = 0
        for vertex in range(n):
            if active[vertex] and degree[vertex] == 1:
                leaves[leaf_count] = vertex
                leaf_count += 1

    var centers = InlineArray[Int64, 2]()
    var center_count = 0
    for vertex in range(n):
        if active[vertex]:
            centers[center_count] = Int64(vertex)
            center_count += 1
    let required = 8 * center_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(center_count):
        tc_store_i64_le(output, 8 * index, centers[index])
    return Int64(required)
