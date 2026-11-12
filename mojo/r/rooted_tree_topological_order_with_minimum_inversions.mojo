from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 12
comptime MAX_INPUT_VALUES = 3 * MAX_N + 1
comptime MAX_OUTPUT_WORDS = MAX_N + 1
comptime MAX_WEIGHT = 1_000_000

fn compare_ratio(left_c: Int64, left_d: Int64, right_c: Int64, right_d: Int64) -> Int:
    let left_zero = left_c == 0 and left_d == 0
    let right_zero = right_c == 0 and right_d == 0
    if left_zero != right_zero:
        if left_zero:
            return -1
        return 1
    let lhs = left_c * right_d
    let rhs = left_d * right_c
    if lhs > rhs:
        return 1
    if lhs < rhs:
        return -1
    return 0

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("rooted_tree_topological_order_with_minimum_inversions")
fn rooted_tree_topological_order_with_minimum_inversions(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT_VALUES):
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N or length != c_size_t(3 * n_value):
        return -1
    let n = Int(n_value)

    var tree_parent = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(1, n):
        let p = input[vertex]
        if p < 0 or p >= vertex:
            return -1
        tree_parent[vertex] = Int(p)

    var original_c = InlineArray[Int64, MAX_N](fill=0)
    var original_d = InlineArray[Int64, MAX_N](fill=0)
    var aggregate_c = InlineArray[Int64, MAX_N](fill=0)
    var aggregate_d = InlineArray[Int64, MAX_N](fill=0)
    var sum_c: Int64 = 0
    var sum_d: Int64 = 0
    for vertex in range(n):
        let c = input[n + vertex]
        let d = input[2 * n + vertex]
        if c < 0 or c > MAX_WEIGHT or d < 0 or d > MAX_WEIGHT:
            return -1
        sum_c += c
        sum_d += d
        if sum_c > MAX_WEIGHT or sum_d > MAX_WEIGHT:
            return -1
        original_c[vertex] = c
        original_d[vertex] = d
        aggregate_c[vertex] = c
        aggregate_d[vertex] = d

    var dsu_parent = InlineArray[Int, MAX_N](fill=0)
    var component_label = InlineArray[Int, MAX_N](fill=0)
    var active = InlineArray[Bool, MAX_N](fill=False)
    var link = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(n):
        dsu_parent[vertex] = vertex
        component_label[vertex] = vertex
        active[vertex] = vertex != 0
        link[vertex] = vertex

    for _ in range(n - 1):
        var selected = -1
        for candidate in range(1, n):
            if not active[candidate]:
                continue
            if selected < 0:
                selected = candidate
                continue
            let comparison = compare_ratio(
                aggregate_c[candidate], aggregate_d[candidate],
                aggregate_c[selected], aggregate_d[selected])
            if comparison > 0 or (comparison == 0 and candidate > selected):
                selected = candidate
        if selected < 0:
            return -1

        var parent_component = tree_parent[selected]
        while dsu_parent[parent_component] != parent_component:
            parent_component = dsu_parent[parent_component]
        let target = component_label[parent_component]
        var child_component = selected
        while dsu_parent[child_component] != child_component:
            child_component = dsu_parent[child_component]
        if child_component == parent_component:
            return -1
        aggregate_c[target] += aggregate_c[selected]
        aggregate_d[target] += aggregate_d[selected]
        dsu_parent[child_component] = parent_component
        component_label[parent_component] = target
        active[selected] = False
        if target != 0:
            active[target] = True
        let next = link[selected]
        link[selected] = link[target]
        link[target] = next

    var traversal = InlineArray[Int, MAX_N](fill=0)
    var count = 0
    var vertex = link[0]
    while count < n:
        traversal[count] = vertex
        count += 1
        if vertex == 0:
            break
        vertex = link[vertex]
    if count != n or traversal[count - 1] != 0:
        return -1

    var words = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    var prefix_d: Int64 = 0
    var objective: Int64 = 0
    for index in range(n):
        let ordered_vertex = traversal[n - 1 - index]
        words[index + 1] = Int64(ordered_vertex)
        objective += prefix_d * original_c[ordered_vertex]
        prefix_d += original_d[ordered_vertex]
    words[0] = objective
    let output_bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for word in range(n + 1):
        store_i64_le(output, 8 * word, words[word])
    return Int64(output_bytes)
