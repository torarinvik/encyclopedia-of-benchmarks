from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 128
comptime MAX_Q = 256
comptime MAX_INPUT_VALUES = 2 * MAX_N + 1 + 3 * MAX_Q
comptime MAX_VALUE = 1_000_000

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("vertex_add_subtree_sum")
fn vertex_add_subtree_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_VALUES):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 * n + 1 + 3 * q):
        return -1

    var values = InlineArray[Int64, MAX_N](fill=0)
    var first_child = InlineArray[Int64, MAX_N](fill=-1)
    var next_sibling = InlineArray[Int64, MAX_N](fill=-1)
    for vertex in range(n):
        values[vertex] = input[2 + vertex]
        if values[vertex] < 0 or values[vertex] > MAX_VALUE:
            return -1
    let parent_start = 2 + n
    for vertex in range(1, n):
        let parent_value = input[parent_start + vertex - 1]
        if parent_value < 0 or parent_value >= vertex:
            return -1
        let parent = Int(parent_value)
        next_sibling[vertex] = first_child[parent]
        first_child[parent] = Int64(vertex)

    var tin = InlineArray[Int, MAX_N](fill=0)
    var tout = InlineArray[Int, MAX_N](fill=0)
    var stack_node = InlineArray[Int, MAX_N](fill=0)
    var stack_next_child = InlineArray[Int64, MAX_N](fill=0)
    var timer = 0
    var top = 1
    stack_node[0] = 0
    stack_next_child[0] = first_child[0]
    tin[0] = timer
    timer += 1
    while top > 0:
        let frame = top - 1
        let child_value = stack_next_child[frame]
        if child_value < 0:
            tout[stack_node[frame]] = timer
            top -= 1
            continue
        let child = Int(child_value)
        stack_next_child[frame] = next_sibling[child]
        tin[child] = timer
        timer += 1
        stack_node[top] = child
        stack_next_child[top] = first_child[child]
        top += 1

    var fenwick = InlineArray[Int64, MAX_N + 1](fill=0)
    for vertex in range(n):
        var index = tin[vertex] + 1
        while index <= n:
            fenwick[index] += values[vertex]
            index += index & (-index)

    var answers = InlineArray[Int64, MAX_Q](fill=0)
    var answer_count = 0
    let operation_start = parent_start + n - 1
    for operation_index in range(q):
        let offset = operation_start + 3 * operation_index
        let kind = input[offset]
        let vertex_value = input[offset + 1]
        let operand = input[offset + 2]
        if kind == 0:
            if vertex_value < 0 or vertex_value >= n_value or operand < 0 or operand > MAX_VALUE:
                return -1
            let vertex = Int(vertex_value)
            values[vertex] += operand
            var index = tin[vertex] + 1
            while index <= n:
                fenwick[index] += operand
                index += index & (-index)
        elif kind == 1:
            if vertex_value < 0 or vertex_value >= n_value or operand != 0:
                return -1
            let vertex = Int(vertex_value)
            var right = tout[vertex]
            var right_sum: Int64 = 0
            while right > 0:
                right_sum += fenwick[right]
                right -= right & (-right)
            var left = tin[vertex]
            var left_sum: Int64 = 0
            while left > 0:
                left_sum += fenwick[left]
                left -= left & (-left)
            answers[answer_count] = right_sum - left_sum
            answer_count += 1
        else:
            return -1

    let output_bytes = 8 * answer_count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)):
        return -2
    for answer in range(answer_count):
        store_i64_le(output, answer * 8, answers[answer])
    return Int64(output_bytes)
