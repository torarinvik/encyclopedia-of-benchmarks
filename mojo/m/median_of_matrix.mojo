from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("median_of_matrix")
fn median_of_matrix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 145:
        return -1
    if input[0] < 0 or input[0] > 16:
        return -1
    let rows = Int(input[0])
    let input_length = Int(length)
    var cursor = 1
    var count = 0
    var values = InlineArray[Int64, 128](fill=0)
    for _ in range(rows):
        if cursor >= input_length:
            return -1
        let row_length = input[cursor]
        cursor += 1
        if row_length == -1:
            continue
        if row_length < 0 or row_length > 128:
            return -1
        let cells = Int(row_length)
        if cells > 128 - count or cells > input_length - cursor:
            return -1
        for _ in range(cells):
            let value = input[cursor]
            if value < -2147483648 or value > 2147483647:
                return -1
            values[count] = value
            count += 1
            cursor += 1
    if cursor != input_length or count == 0:
        return -1
    for i in range(1, count):
        let value = values[i]
        var j = i
        while j > 0 and values[j - 1] > value:
            values[j] = values[j - 1]
            j -= 1
        values[j] = value
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 4:
        return -2
    let median = values[(count - 1) // 2]
    for byte in range(4):
        output[byte] = UInt8((median >> (8 * byte)) & 255)
    return 4
