from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_SIZE = 64
comptime MAX_OPS = 64
comptime MAX_INPUT_LENGTH = 194


fn previous_bucket(index: Int64) -> Int64:
    return (index & (index + 1)) - 1


fn write_i64_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))


@export("maximum_fenwick_tree")
fn maximum_fenwick_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let size = input[0]
    let operation_count = input[1]
    if size < 1 or size > MAX_SIZE or operation_count < 0 or operation_count > MAX_OPS:
        return -1
    if Int(length) != 2 + 3 * Int(operation_count):
        return -1

    var values = InlineArray[Int64, MAX_SIZE](fill=0)
    var tree = InlineArray[Int64, MAX_SIZE](fill=0)
    var results = InlineArray[Int64, MAX_OPS](fill=0)
    var result_count = 0
    for operation in range(Int(operation_count)):
        let position = 2 + 3 * operation
        let opcode = input[position]
        let first = input[position + 1]
        let second = input[position + 2]
        if opcode == 0:
            if first < 0 or first >= size or second < 0 or second > 2147483647:
                return -1
            var index = Int(first)
            let old_value = values[index]
            let value = second
            values[index] = value
            while index < Int(size):
                let old_max = tree[index]
                if value > old_max:
                    tree[index] = value
                elif old_value == old_max:
                    let left = previous_bucket(Int64(index)) + 1
                    var maximum = value
                    if Int64(left) != Int64(index) and maximum < 0:
                        maximum = 0
                    var child = Int64(index) - 1
                    while child >= left:
                        if tree[Int(child)] > maximum:
                            maximum = tree[Int(child)]
                        if maximum == old_max:
                            break
                        child = previous_bucket(child)
                    tree[index] = maximum
                    if maximum == old_max:
                        break
                else:
                    break
                index = index | (index + 1)
        elif opcode == 1:
            if first < 0 or first > second or second > size:
                return -1
            var maximum: Int64 = 0
            var right = second - 1
            while first <= right:
                let current_left = right & (right + 1)
                if first <= current_left:
                    if tree[Int(right)] > maximum:
                        maximum = tree[Int(right)]
                    right = current_left - 1
                else:
                    if values[Int(right)] > maximum:
                        maximum = values[Int(right)]
                    right -= 1
            results[result_count] = maximum
            result_count += 1
        else:
            return -1

    let byte_count = result_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(byte_count):
        return -2
    for index in range(result_count):
        write_i64_le(output, index * 8, results[index])
    return Int64(byte_count)
