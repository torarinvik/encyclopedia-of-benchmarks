from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_NODES = 128
comptime MAX_INPUT_LENGTH = 130


fn write_i32_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int32
):
    let bits = UInt32(value)
    for byte in range(4):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt32(255))


@export("merge_sorted_singly_linked_list")
fn merge_sorted_singly_linked_list(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let len_a = input[0]
    if len_a < 0 or len_a > MAX_NODES or Int(len_a) > Int(length) - 2:
        return -1
    let len_b_position = 1 + Int(len_a)
    let len_b = input[len_b_position]
    if len_b < 0 or len_b > MAX_NODES - len_a:
        return -1
    let total = Int(len_a + len_b)
    if Int(length) != 2 + total:
        return -1

    var values = InlineArray[Int32, MAX_NODES](fill=0)
    var next = InlineArray[Int32, MAX_NODES](fill=-1)
    var origins = InlineArray[Int32, MAX_NODES](fill=0)
    var positions = InlineArray[Int32, MAX_NODES](fill=0)
    for index in range(Int(len_a)):
        let raw = input[index + 1]
        if raw < -2147483648 or raw > 2147483647 or (index > 0 and input[index] > raw):
            return -1
        values[index] = Int32(raw)
        origins[index] = 0
        positions[index] = Int32(index)
        if index + 1 < Int(len_a):
            next[index] = Int32(index + 1)

    let b_start = len_b_position + 1
    for index in range(Int(len_b)):
        let raw = input[b_start + index]
        if (
            raw < -2147483648 or raw > 2147483647
            or (index > 0 and input[b_start + index - 1] > raw)
        ):
            return -1
        let node = Int(len_a) + index
        values[node] = Int32(raw)
        origins[node] = 1
        positions[node] = Int32(index)
        if index + 1 < Int(len_b):
            next[node] = Int32(node + 1)

    var head_a = Int32(-1)
    var head_b = Int32(-1)
    if len_a > 0:
        head_a = 0
    if len_b > 0:
        head_b = Int32(len_a)
    var merged_head = Int32(-1)
    var tail = Int32(-1)
    while head_a >= 0 and head_b >= 0:
        var node = head_a
        if values[Int(head_a)] <= values[Int(head_b)]:
            head_a = next[Int(node)]
        else:
            node = head_b
            head_b = next[Int(node)]
        if tail < 0:
            merged_head = node
        else:
            next[Int(tail)] = node
        tail = node
    var remainder = head_b
    if head_a >= 0:
        remainder = head_a
    if tail < 0:
        merged_head = remainder
    else:
        next[Int(tail)] = remainder

    let output_bytes = total * 12
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    var written = 0
    var node = merged_head
    while node >= 0:
        write_i32_le(output, written, values[Int(node)])
        write_i32_le(output, written + 4, origins[Int(node)])
        write_i32_le(output, written + 8, positions[Int(node)])
        written += 12
        node = next[Int(node)]
    return Int64(output_bytes)
