from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_ROWS = 16
comptime MAX_CELLS = 128
comptime MAX_INPUT_WORDS = 1 + MAX_ROWS + MAX_CELLS


fn write_i32_le(output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64):
    let bits = UInt32(Int32(value))
    for byte in range(4):
        output[byte] = UInt8((bits >> (8 * byte)) & UInt32(255))


@export("median_of_matrix")
fn median_of_matrix(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if (
        input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1
        or length > c_size_t(MAX_INPUT_WORDS)
    ):
        return -1
    let word_count = Int(length)
    let row_count = input[0]
    if row_count < 0 or row_count > MAX_ROWS:
        return -1

    var values = InlineArray[Int64, MAX_CELLS](fill=0)
    var cursor = 1
    var value_count = 0
    for _ in range(Int(row_count)):
        if cursor >= word_count:
            return -1
        let row_length = input[cursor]
        cursor += 1
        if row_length == -1:
            continue
        if row_length < 0 or row_length > MAX_CELLS:
            return -1
        let cells = Int(row_length)
        if cells > MAX_CELLS - value_count or cells > word_count - cursor:
            return -1
        for _ in range(cells):
            let value = input[cursor]
            cursor += 1
            if value < -2147483648 or value > 2147483647:
                return -1
            values[value_count] = value
            value_count += 1
    if cursor != word_count or value_count == 0:
        return -1

    for index in range(1, value_count):
        let value = values[index]
        var position = index
        while position > 0 and values[position - 1] > value:
            values[position] = values[position - 1]
            position -= 1
        values[position] = value

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 4:
        return -2
    write_i32_le(output, values[(value_count - 1) // 2])
    return 4
