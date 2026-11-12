from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_NODES = 256
alias MAX_QUERIES = 1024
alias MAX_ARCS = 510
alias MAX_EULER = 2 * MAX_NODES - 1
alias MAX_BLOCKS = 128
alias MAX_LEVELS = 8
alias MAX_MICRO = 4

@export("lowest_common_ancestor_farach_colton_bender")
fn lowest_common_ancestor_farach_colton_bender(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4: return -1
    if input[0] < 1 or input[0] > MAX_NODES: return -1
    let n_value = input[0]
    let n = Int(n_value)
    if input[1] < 0 or input[1] >= n_value or input[2] != n_value - 1 or input[3] < 0 or input[3] > MAX_QUERIES: return -1
    let edge_count = Int(input[2])
    let query_count = Int(input[3])
    let query_offset = 4 + 2 * edge_count
    if length != c_size_t(query_offset + 2 * query_count): return -1
    let root = Int(input[1])

    var head = InlineArray[Int, MAX_NODES]()
    var arc_to = InlineArray[Int, MAX_ARCS]()
    var arc_next = InlineArray[Int, MAX_ARCS]()
    var parent = InlineArray[Int, MAX_NODES]()
    var tree_depth = InlineArray[Int, MAX_NODES]()
    var first = InlineArray[Int, MAX_NODES]()
    var euler = InlineArray[Int, MAX_EULER]()
    var euler_depth = InlineArray[Int, MAX_EULER]()
    var stack_node = InlineArray[Int, MAX_NODES]()
    var stack_arc = InlineArray[Int, MAX_NODES]()
    for node in range(n):
        head[node] = -1
        parent[node] = -2
    var arcs = 0
    for edge in range(edge_count):
        let u = input[4 + 2 * edge]
        let v = input[5 + 2 * edge]
        if u < 0 or u >= n or v < 0 or v >= n or u == v: return -1
        let a = Int(u)
        let b = Int(v)
        arc_to[arcs] = b
        arc_next[arcs] = head[a]
        head[a] = arcs
        arcs += 1
        arc_to[arcs] = a
        arc_next[arcs] = head[b]
        head[b] = arcs
        arcs += 1
    for query in range(query_count):
        for side in range(2):
            let node = input[query_offset + 2 * query + side]
            if node < 0 or node >= n: return -1

    var euler_count = 1
    var top = 1
    var reached = 1
    parent[root] = -1
    first[root] = 0
    euler[0] = root
    stack_node[0] = root
    stack_arc[0] = head[root]
    while top > 0:
        let slot = top - 1
        let node = stack_node[slot]
        let arc = stack_arc[slot]
        if arc < 0:
            top -= 1
            if top > 0:
                let up = stack_node[top - 1]
                euler[euler_count] = up
                euler_depth[euler_count] = tree_depth[up]
                euler_count += 1
            continue
        stack_arc[slot] = arc_next[arc]
        let neighbor = arc_to[arc]
        if neighbor == parent[node]: continue
        if parent[neighbor] != -2: return -1
        parent[neighbor] = node
        tree_depth[neighbor] = tree_depth[node] + 1
        first[neighbor] = euler_count
        euler[euler_count] = neighbor
        euler_depth[euler_count] = tree_depth[neighbor]
        euler_count += 1
        reached += 1
        stack_node[top] = neighbor
        stack_arc[top] = head[neighbor]
        top += 1
    if reached != n: return -1
    if output_capacity < c_size_t(query_count) or (query_count > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2

    var logarithm = 0
    var value = euler_count
    while value > 1:
        value = value // 2
        logarithm += 1
    var block_size = logarithm // 2
    if block_size < 1: block_size = 1
    let block_count = (euler_count + block_size - 1) // block_size
    var micro = InlineArray[Int, 8 * 4 * 4]()
    var pattern = InlineArray[Int, MAX_BLOCKS]()
    var logs = InlineArray[Int, MAX_BLOCKS + 1]()
    var macro_table = InlineArray[Int, MAX_LEVELS * MAX_BLOCKS]()
    let shape_count = 1 << (block_size - 1)
    for shape in range(shape_count):
        var relative = InlineArray[Int, MAX_MICRO]()
        for step in range(block_size - 1):
            let direction = if ((shape >> step) & 1) != 0: 1 else: -1
            relative[step + 1] = relative[step] + direction
        for left in range(block_size):
            for right in range(left, block_size):
                var best = left
                for at in range(left + 1, right + 1):
                    if relative[at] < relative[best]: best = at
                micro[shape * 16 + left * 4 + right] = best
    for block in range(block_count):
        let base = block * block_size
        let end = min(base + block_size, euler_count)
        var best = base
        for at in range(base, end - 1):
            if euler_depth[at + 1] > euler_depth[at]: pattern[block] |= 1 << (at - base)
            let candidate = at + 1
            if euler_depth[candidate] < euler_depth[best] or
                (euler_depth[candidate] == euler_depth[best] and candidate < best): best = candidate
        macro_table[block] = best
    for count in range(2, block_count + 1): logs[count] = logs[count // 2] + 1
    var macro_levels = 1
    while (1 << macro_levels) <= block_count and macro_levels < MAX_LEVELS:
        let half = 1 << (macro_levels - 1)
        let span = 2 * half
        for block in range(block_count - span + 1):
            let a = macro_table[(macro_levels - 1) * MAX_BLOCKS + block]
            let b = macro_table[(macro_levels - 1) * MAX_BLOCKS + block + half]
            let best = if euler_depth[a] < euler_depth[b] or
                (euler_depth[a] == euler_depth[b] and a < b): a else: b
            macro_table[macro_levels * MAX_BLOCKS + block] = best
        macro_levels += 1

    var answers = InlineArray[UInt8, MAX_QUERIES]()
    for query in range(query_count):
        let u = Int(input[query_offset + 2 * query])
        let v = Int(input[query_offset + 2 * query + 1])
        var left = first[u]
        var right = first[v]
        if left > right:
            let temp = left
            left = right
            right = temp
        let block_a = left // block_size
        let block_b = right // block_size
        var best = 0
        if block_a == block_b:
            best = block_a * block_size + micro[pattern[block_a] * 16 + (left % block_size) * 4 + (right % block_size)]
        else:
            let base_a = block_a * block_size
            let base_b = block_b * block_size
            let len_a = min(block_size, euler_count - base_a)
            best = base_a + micro[pattern[block_a] * 16 + (left % block_size) * 4 + len_a - 1]
            let right_best = base_b + micro[pattern[block_b] * 16 + (right % block_size)]
            if euler_depth[right_best] < euler_depth[best] or
                (euler_depth[right_best] == euler_depth[best] and right_best < best): best = right_best
            if block_b > block_a + 1:
                let lo = block_a + 1
                let hi = block_b - 1
                let count = hi - lo + 1
                let level = logs[count]
                let span = 1 << level
                let a = macro_table[level * MAX_BLOCKS + lo]
                let b = macro_table[level * MAX_BLOCKS + hi - span + 1]
                let middle = if euler_depth[a] < euler_depth[b] or
                    (euler_depth[a] == euler_depth[b] and a < b): a else: b
                if euler_depth[middle] < euler_depth[best] or
                    (euler_depth[middle] == euler_depth[best] and middle < best): best = middle
        answers[query] = UInt8(euler[best])
    for query in range(query_count): output[query] = answers[query]
    Int64(query_count)
