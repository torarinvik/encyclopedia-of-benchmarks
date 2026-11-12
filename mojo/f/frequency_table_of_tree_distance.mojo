from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_INPUT_VALUES = 1 + 2 * (MAX_N - 1)

fn ftd_find_root(mut parent: InlineArray[Int, MAX_N], item: Int) -> Int:
    var node = item
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn ftd_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("frequency_table_of_tree_distance")
fn frequency_table_of_tree_distance(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(1 + 2 * (n - 1)):
        return -1

    var adjacent = InlineArray[Bool, MAX_N * MAX_N]()
    var dsu_parent = InlineArray[Int, MAX_N]()
    var dsu_size = InlineArray[Int, MAX_N]()
    for vertex in range(n):
        dsu_parent[vertex] = vertex
        dsu_size[vertex] = 1
    for edge in range(n - 1):
        let offset = 1 + 2 * edge
        let left_value = input[offset]
        let right_value = input[offset + 1]
        if left_value < 0 or left_value >= n_value or right_value < 0 or (
            right_value >= n_value or left_value == right_value
        ):
            return -1
        let left = Int(left_value)
        let right = Int(right_value)
        var root_left = ftd_find_root(mut dsu_parent, left)
        var root_right = ftd_find_root(mut dsu_parent, right)
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

    var removed = InlineArray[Bool, MAX_N]()
    var answer = InlineArray[Int64, MAX_N]()
    var pending = InlineArray[Int, MAX_N]()
    var pending_count = 1
    pending[0] = 0
    while pending_count > 0:
        pending_count -= 1
        let start = pending[pending_count]

        var order = InlineArray[Int, MAX_N]()
        var parent = InlineArray[Int, MAX_N]()
        var subtree = InlineArray[Int, MAX_N]()
        var stack = InlineArray[Int, MAX_N]()
        var order_count = 0
        var top = 1
        stack[0] = start
        parent[start] = start
        subtree[start] = 1
        order[order_count] = start
        order_count += 1
        while top > 0:
            top -= 1
            let vertex = stack[top]
            for neighbor in range(n):
                if not adjacent[vertex * MAX_N + neighbor] or removed[neighbor] or neighbor == parent[vertex]:
                    continue
                parent[neighbor] = vertex
                subtree[neighbor] = 1
                order[order_count] = neighbor
                order_count += 1
                stack[top] = neighbor
                top += 1
        var position = order_count
        while position > 1:
            position -= 1
            let vertex = order[position]
            subtree[parent[vertex]] += subtree[vertex]

        var centroid = MAX_N
        for index in range(order_count):
            let vertex = order[index]
            var largest_part = order_count - subtree[vertex]
            for neighbor in range(n):
                if adjacent[vertex * MAX_N + neighbor] and not removed[neighbor] and (
                    parent[neighbor] == vertex and subtree[neighbor] > largest_part
                ):
                    largest_part = subtree[neighbor]
            if 2 * largest_part <= order_count and (centroid == MAX_N or vertex < centroid):
                centroid = vertex

        var frequency = InlineArray[Int64, MAX_N]()
        var frequency_max = 0
        frequency[0] = 1
        removed[centroid] = True
        for child in range(n):
            if not adjacent[centroid * MAX_N + child] or removed[child]:
                continue
            var local_frequency = InlineArray[Int, MAX_N]()
            var walk_vertex = InlineArray[Int, MAX_N]()
            var walk_parent = InlineArray[Int, MAX_N]()
            var walk_depth = InlineArray[Int, MAX_N]()
            var local_max = 0
            var walk_top = 1
            walk_vertex[0] = child
            walk_parent[0] = centroid
            walk_depth[0] = 1
            while walk_top > 0:
                walk_top -= 1
                let vertex = walk_vertex[walk_top]
                let previous = walk_parent[walk_top]
                let depth = walk_depth[walk_top]
                local_frequency[depth] += 1
                if depth > local_max:
                    local_max = depth
                for neighbor in range(n):
                    if adjacent[vertex * MAX_N + neighbor] and not removed[neighbor] and neighbor != previous:
                        walk_vertex[walk_top] = neighbor
                        walk_parent[walk_top] = vertex
                        walk_depth[walk_top] = depth + 1
                        walk_top += 1
            for depth in range(1, local_max + 1):
                for other in range(frequency_max + 1):
                    if depth + other < n:
                        answer[depth + other] += Int64(local_frequency[depth]) * frequency[other]
            for depth in range(1, local_max + 1):
                frequency[depth] += Int64(local_frequency[depth])
            if local_max > frequency_max:
                frequency_max = local_max

        for child in range(n):
            if adjacent[centroid * MAX_N + child] and not removed[child]:
                pending[pending_count] = child
                pending_count += 1

    let required = 8 * (n - 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for distance in range(1, n):
        ftd_store_i64_le(output, 8 * (distance - 1), answer[distance])
    return Int64(required)
