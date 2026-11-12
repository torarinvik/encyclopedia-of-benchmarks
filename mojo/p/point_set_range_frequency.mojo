from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 64
comptime MAX_VALUES = MAX_N + MAX_Q
comptime STRIDE = MAX_N + 1
comptime MAX_TREE = MAX_VALUES * STRIDE
comptime MAX_PARSEABLE_INPUT = 2 + MAX_N + 4 * MAX_Q + 1
comptime MAX_OUTPUT_BYTES = 8 * MAX_Q
comptime MAX_VALUE = 1_000_000

fn lowbit(value: Int) -> Int:
    return value & (-value)

fn lower_bound(values: UnsafePointer[Int64, ImmutAnyOrigin], count: Int, target: Int64) -> Int:
    var left = 0
    var right = count
    while left < right:
        let middle = left + (right - left) // 2
        if values[middle] < target:
            left = middle + 1
        else:
            right = middle
    return left

fn sort_unique(values: UnsafePointer[Int64, MutAnyOrigin], count: Int) -> Int:
    for index in range(1, count):
        let value = values[index]
        var position = index
        while position > 0 and values[position - 1] > value:
            values[position] = values[position - 1]
            position -= 1
        values[position] = value
    var unique_count = 0
    for index in range(count):
        if unique_count == 0 or values[index] != values[unique_count - 1]:
            values[unique_count] = values[index]
            unique_count += 1
    return unique_count

fn fenwick_add(tree: UnsafePointer[Int64, MutAnyOrigin], value_id: Int,
    position: Int, n: Int, delta: Int64):
    var index = position + 1
    let row = value_id * STRIDE
    while index <= n:
        tree[row + index] += delta
        index += lowbit(index)

fn fenwick_prefix(tree: UnsafePointer[Int64, MutAnyOrigin], value_id: Int, count: Int) -> Int64:
    var index = count
    let row = value_id * STRIDE
    var total: Int64 = 0
    while index > 0:
        total += tree[row + index]
        index -= lowbit(index)
    return total

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("point_set_range_frequency")
fn point_set_range_frequency(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_PARSEABLE_INPUT):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if 2 + n > length:
        return -1

    var values = InlineArray[Int64, MAX_VALUES](fill=0)
    var initial = InlineArray[Int64, MAX_N](fill=0)
    var kinds = InlineArray[Int64, MAX_Q](fill=0)
    var op_a = InlineArray[Int64, MAX_Q](fill=0)
    var op_b = InlineArray[Int64, MAX_Q](fill=0)
    var op_c = InlineArray[Int64, MAX_Q](fill=0)
    var value_count = 0
    for index in range(n):
        let value = input[2 + index]
        if value < 0 or value > MAX_VALUE:
            return -1
        initial[index] = value
        values[value_count] = value
        value_count += 1

    var cursor = 2 + n
    var query_count = 0
    for index in range(q):
        if cursor >= length:
            return -1
        let kind = input[cursor]
        cursor += 1
        kinds[index] = kind
        if kind == 0:
            if cursor + 2 > length:
                return -1
            let position = input[cursor]
            let value = input[cursor + 1]
            cursor += 2
            if position < 0 or position >= n_value or value < 0 or value > MAX_VALUE:
                return -1
            op_a[index] = position
            op_b[index] = value
            values[value_count] = value
            value_count += 1
        elif kind == 1:
            if cursor + 3 > length:
                return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            let value = input[cursor + 2]
            cursor += 3
            if left < 0 or left > right or right > n_value or value < 0 or value > MAX_VALUE:
                return -1
            op_a[index] = left
            op_b[index] = right
            op_c[index] = value
            query_count += 1
        else:
            return -1
    if cursor != length:
        return -1
    let output_bytes = 8 * query_count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)):
        return -2

    let unique_count = sort_unique(values.unsafe_ptr(), value_count)
    var tree = InlineArray[Int64, MAX_TREE](fill=0)
    var current = InlineArray[Int, MAX_N](fill=0)
    for index in range(n):
        current[index] = lower_bound(values.unsafe_ptr(), unique_count, initial[index])
        fenwick_add(tree.unsafe_ptr(), current[index], index, n, 1)
    var staging = InlineArray[UInt8, MAX_OUTPUT_BYTES](fill=0)
    var answer = 0
    for index in range(q):
        if kinds[index] == 0:
            let position = Int(op_a[index])
            let next = lower_bound(values.unsafe_ptr(), unique_count, op_b[index])
            if current[position] != next:
                fenwick_add(tree.unsafe_ptr(), current[position], position, n, -1)
                fenwick_add(tree.unsafe_ptr(), next, position, n, 1)
                current[position] = next
        else:
            let id = lower_bound(values.unsafe_ptr(), unique_count, op_c[index])
            var count: Int64 = 0
            if id < unique_count and values[id] == op_c[index]:
                count = fenwick_prefix(tree.unsafe_ptr(), id, Int(op_b[index])) -
                        fenwick_prefix(tree.unsafe_ptr(), id, Int(op_a[index]))
            store_i64_le(staging.unsafe_ptr(), 8 * answer, count)
            answer += 1
    if output_bytes > 0:
        for byte in range(output_bytes):
            output[byte] = staging[byte]
    return Int64(output_bytes)
