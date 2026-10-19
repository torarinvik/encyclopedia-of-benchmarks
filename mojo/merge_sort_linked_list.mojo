from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_ITEMS = 128


fn merge_nodes(
    values: InlineArray[Int32, MAX_ITEMS],
    mut next: InlineArray[Int32, MAX_ITEMS],
    left: Int32,
    right: Int32,
) -> Int32:
    if left < 0:
        return right
    if right < 0:
        return left
    if values[Int(left)] <= values[Int(right)]:
        next[Int(left)] = merge_nodes(values, next, next[Int(left)], right)
        return left
    next[Int(right)] = merge_nodes(values, next, left, next[Int(right)])
    return right


fn merge_sort_nodes(
    values: InlineArray[Int32, MAX_ITEMS],
    mut next: InlineArray[Int32, MAX_ITEMS],
    head: Int32,
) -> Int32:
    if head < 0 or next[Int(head)] < 0:
        return head
    var slow = head
    var fast = next[Int(head)]
    while fast >= 0 and next[Int(fast)] >= 0:
        slow = next[Int(slow)]
        fast = next[Int(next[Int(fast)])]
    let right_head = next[Int(slow)]
    next[Int(slow)] = -1
    let left = merge_sort_nodes(values, next, head)
    let right = merge_sort_nodes(values, next, right_head)
    return merge_nodes(values, next, left, right)


fn write_i32_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int32
):
    let bits = UInt32(value)
    for byte in range(4):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt32(255))


@export("merge_sort_linked_list")
fn merge_sort_linked_list(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_ITEMS + 1):
        return -1
    let count = input[0]
    if count < 0 or count > MAX_ITEMS or Int(length) != 1 + Int(count):
        return -1
    var values = InlineArray[Int32, MAX_ITEMS](fill=0)
    var next = InlineArray[Int32, MAX_ITEMS](fill=-1)
    for index in range(Int(count)):
        let raw = input[index + 1]
        if raw < -2147483648 or raw > 2147483647:
            return -1
        let value = Int32(raw)
        for previous in range(index):
            if values[previous] == value:
                return -1
        values[index] = value
        if index + 1 < Int(count):
            next[index] = Int32(index + 1)

    var head = Int32(-1)
    if count > 0:
        head = merge_sort_nodes(values, next, Int32(0))
    let required = Int(count) * 4
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(required):
        return -2
    var node = head
    for index in range(Int(count)):
        write_i32_le(output, index * 4, values[Int(node)])
        node = next[Int(node)]
    return Int64(required)
