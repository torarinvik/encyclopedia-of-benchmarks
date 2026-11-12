from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_K = 32
comptime MAX_INPUT = 66
comptime MAX_VIRTUAL = 32
comptime MAX_CANDIDATES = 64
comptime MAX_WORDS = 1 + 3 * MAX_VIRTUAL

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

fn lca(a0: Int, b0: Int, parent: InlineArray[Int, MAX_N],
       depth: InlineArray[Int, MAX_N]) -> Int:
    var a = a0
    var b = b0
    while depth[a] > depth[b]: a = parent[a]
    while depth[b] > depth[a]: b = parent[b]
    while a != b:
        a = parent[a]
        b = parent[b]
    return a

fn is_ancestor(a: Int, b: Int, tin: InlineArray[Int, MAX_N],
               tout: InlineArray[Int, MAX_N]) -> Bool:
    return tin[a] <= tin[b] and tin[b] < tout[a]

@export("virtual_tree")
fn virtual_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT):
        return -1
    let n_value = input[0]
    let k_value = input[1]
    if n_value < 1 or n_value > MAX_N or k_value < 0 or k_value > MAX_K or k_value > n_value:
        return -1
    let n = Int(n_value)
    let k = Int(k_value)
    if length != c_size_t(n + k + 1): return -1

    var parent = InlineArray[Int, MAX_N](fill=0)
    var depth = InlineArray[Int, MAX_N](fill=0)
    var children = InlineArray[Int, MAX_N * MAX_N](fill=0)
    var child_count = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(1, n):
        let p_value = input[vertex + 1]
        if p_value < 0 or p_value >= n_value or p_value == vertex: return -1
        let p = Int(p_value)
        parent[vertex] = p
        children[p * MAX_N + child_count[p]] = vertex
        child_count[p] += 1

    var marks = InlineArray[Int, MAX_K](fill=0)
    for index in range(k):
        let mark_value = input[n + 1 + index]
        if mark_value < 0 or mark_value >= n_value: return -1
        marks[index] = Int(mark_value)
        for previous in range(index):
            if marks[previous] == marks[index]: return -1

    var tin = InlineArray[Int, MAX_N](fill=MAX_N)
    var tout = InlineArray[Int, MAX_N](fill=MAX_N)
    var node_stack = InlineArray[Int, MAX_N](fill=0)
    var next_stack = InlineArray[Int, MAX_N](fill=0)
    var timer = 0
    var top = 1
    var reached = 1
    node_stack[0] = 0
    tin[0] = timer
    timer += 1
    while top > 0:
        let frame = top - 1
        let current = node_stack[frame]
        if next_stack[frame] == child_count[current]:
            tout[current] = timer
            top -= 1
            continue
        let child = children[current * MAX_N + next_stack[frame]]
        next_stack[frame] += 1
        if tin[child] != MAX_N: return -1
        tin[child] = timer
        timer += 1
        depth[child] = depth[current] + 1
        reached += 1
        node_stack[top] = child
        next_stack[top] = 0
        top += 1
    if reached != n: return -1

    var words = InlineArray[Int64, MAX_WORDS](fill=0)
    var word_count = 1
    if k == 0:
        words[0] = 0
    else:
        for index in range(1, k):
            let value = marks[index]
            var position = index
            while position > 0 and tin[marks[position - 1]] > tin[value]:
                marks[position] = marks[position - 1]
                position -= 1
            marks[position] = value
        var nodes = InlineArray[Int, MAX_CANDIDATES](fill=0)
        var count = 0
        nodes[count] = 0
        count += 1
        for index in range(k):
            nodes[count] = marks[index]
            count += 1
        for index in range(1, k):
            nodes[count] = lca(marks[index - 1], marks[index], parent, depth)
            count += 1
        for index in range(1, count):
            let value = nodes[index]
            var position = index
            while position > 0 and tin[nodes[position - 1]] > tin[value]:
                nodes[position] = nodes[position - 1]
                position -= 1
            nodes[position] = value
        var unique = InlineArray[Int, MAX_VIRTUAL](fill=0)
        var unique_count = 0
        for index in range(count):
            if unique_count == 0 or unique[unique_count - 1] != nodes[index]:
                unique[unique_count] = nodes[index]
                unique_count += 1
        words[0] = Int64(unique_count)
        var stack = InlineArray[Int, MAX_VIRTUAL](fill=0)
        var stack_size = 0
        for index in range(unique_count):
            let vertex = unique[index]
            while stack_size > 0 and not is_ancestor(stack[stack_size - 1], vertex, tin, tout):
                stack_size -= 1
            let virtual_parent = stack[stack_size - 1] if stack_size > 0 else vertex
            words[word_count] = Int64(vertex)
            words[word_count + 1] = Int64(virtual_parent)
            words[word_count + 2] = Int64(depth[vertex] - depth[virtual_parent])
            word_count += 3
            stack[stack_size] = vertex
            stack_size += 1

    let output_bytes = word_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for index in range(word_count): put_word(output, index * 8, words[index])
    return Int64(output_bytes)
