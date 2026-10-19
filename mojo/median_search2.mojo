from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_NODES = 128


fn write_i32_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
):
    let bits = UInt32(Int32(value))
    for byte in range(4):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt32(255))


@export("median_search2")
fn median_search2(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_NODES + 1):
        return -1
    let word_count = Int(length)
    let node_count = input[0]
    if node_count < 0 or node_count > MAX_NODES or word_count != Int(node_count) + 1:
        return -1
    for index in range(Int(node_count)):
        let value = input[index + 1]
        if value < -2147483648 or value > 2147483647:
            return -1

    # Model the wrapper-built next links so equal values still identify distinct nodes.
    var next = InlineArray[Int64, MAX_NODES](fill=-1)
    for index in range(Int(node_count) - 1):
        next[index] = Int64(index + 1)

    var found: Int64 = 0
    var selected: Int64 = -1
    if node_count > 0:
        var slow = Int64(0)
        var fast = Int64(0)
        while fast >= 0 and next[Int(fast)] >= 0:
            slow = next[Int(slow)]
            fast = next[Int(next[Int(fast)])]
        found = 1
        selected = slow

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < 8:
        return -2
    write_i32_le(output, 0, found)
    write_i32_le(output, 4, selected)
    return 8
