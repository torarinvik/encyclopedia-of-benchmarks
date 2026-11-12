from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_NODE = 2 * MAX_N - 1
alias MAX_INPUT = MAX_N + 2
alias MAX_WEIGHT = 1_000_000
alias GW_INFINITY = Int64(1) << 62

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("garsia_wachs_alphabetic_tree")
fn garsia_wachs_alphabetic_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 2 or input_length > c_size_t(MAX_INPUT): return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N: return -1
    let n = Int(n_value)
    if input_length != c_size_t(n + 1): return -1

    var node_weight = InlineArray[Int64, MAX_NODE]()
    var left = InlineArray[Int, MAX_NODE]()
    var right = InlineArray[Int, MAX_NODE]()
    var active = InlineArray[Int, MAX_N]()
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] > MAX_WEIGHT: return -1
        node_weight[i] = input[i + 1]
        left[i] = -1
        right[i] = -1
        active[i] = i
    var active_count = n
    var next_node = n
    while active_count > 1:
        var pair = 0
        while pair + 1 < active_count:
            var following = GW_INFINITY
            if pair + 2 < active_count: following = node_weight[active[pair + 2]]
            if node_weight[active[pair]] <= following: break
            pair += 1
        let first = active[pair]
        let second = active[pair + 1]
        let combined = node_weight[first] + node_weight[second]
        node_weight[next_node] = combined
        left[next_node] = first
        right[next_node] = second
        var earlier = pair
        while earlier > 0 and node_weight[active[earlier - 1]] < combined: earlier -= 1
        let insert_at = earlier
        var i = pair
        while i + 2 < active_count:
            active[i] = active[i + 2]
            i += 1
        active_count -= 2
        i = active_count
        while i > insert_at:
            active[i] = active[i - 1]
            i -= 1
        active[insert_at] = next_node
        active_count += 1
        next_node += 1

    var depths = InlineArray[Int, MAX_N]()
    var stack_node = InlineArray[Int, 2 * MAX_N]()
    var stack_depth = InlineArray[Int, 2 * MAX_N]()
    var top = 1
    stack_node[0] = active[0]
    while top > 0:
        top -= 1
        let node = stack_node[top]
        let depth = stack_depth[top]
        if node < n:
            depths[node] = depth
        else:
            stack_node[top] = right[node]
            stack_depth[top] = depth + 1
            top += 1
            stack_node[top] = left[node]
            stack_depth[top] = depth + 1
            top += 1

    var ordered_left = InlineArray[Int, MAX_NODE]()
    var ordered_right = InlineArray[Int, MAX_NODE]()
    var code_node = InlineArray[Int, 2 * MAX_N]()
    var code_depth = InlineArray[Int, 2 * MAX_N]()
    var code_top = 0
    var next_ordered = n
    for leaf in range(n):
        code_node[code_top] = leaf
        code_depth[code_top] = depths[leaf]
        code_top += 1
        while code_top >= 2 and code_depth[code_top - 1] == code_depth[code_top - 2]:
            let level = code_depth[code_top - 1]
            if level <= 0 or next_ordered >= 2 * n - 1: return -1
            ordered_left[next_ordered] = code_node[code_top - 2]
            ordered_right[next_ordered] = code_node[code_top - 1]
            code_top -= 2
            code_node[code_top] = next_ordered
            code_depth[code_top] = level - 1
            code_top += 1
            next_ordered += 1
    if code_top != 1 or code_depth[0] != 0 or next_ordered != 2 * n - 1: return -1

    var cost: Int64 = 0
    for i in range(n): cost += input[i + 1] * Int64(depths[i])
    let output_bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_bytes): return -2
    store_i64(output, 0, cost)
    for i in range(n): store_i64(output, 8 * (i + 1), Int64(depths[i]))
    Int64(output_bytes)
