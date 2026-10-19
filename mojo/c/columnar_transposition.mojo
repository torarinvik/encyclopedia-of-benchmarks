from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("columnar_transposition")
fn columnar_transposition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let operation = input[0]
    let text_n = input[1]
    let raw_n = input[2]
    if (operation != 0 and operation != 1) or text_n < 0 or text_n > 256 or raw_n < 1 or raw_n > 32 or length != 3 + text_n + raw_n: return -1
    var key = InlineArray[UInt8, 32](0)
    var order = InlineArray[Int64, 32](0)
    var key_n: Int64 = 0
    for i in range(text_n):
        if input[3 + i] < 0 or input[3 + i] > 127: return -1
    for i in range(raw_n):
        let ch = input[3 + text_n + i]
        if ch < 0 or ch > 127: return -1
        if ch >= 65 and ch <= 90:
            key[key_n] = UInt8(ch)
            key_n += 1
        elif ch >= 97 and ch <= 122:
            key[key_n] = UInt8(ch - 32)
            key_n += 1
    if key_n == 0: return -1
    for i in range(key_n):
        order[i] = i
        var pos = i
        while pos > 0 and key[order[pos - 1]] > key[i]:
            order[pos] = order[pos - 1]
            pos -= 1
        order[pos] = i
    if text_n == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < text_n: return -2
    let rows = (text_n + key_n - 1) / key_n
    var written: Int64 = 0
    if operation == 0:
        for rank in range(key_n):
            let column = order[rank]
            for row in range(rows):
                let index = row * key_n + column
                if index < text_n:
                    output[written] = UInt8(input[3 + index])
                    written += 1
        return written
    var column_lengths = InlineArray[Int64, 32](0)
    var column_data = InlineArray[UInt8, 8192](0)
    let remainder = text_n % key_n
    for column in range(key_n):
        column_lengths[column] = rows if remainder == 0 or column < remainder else rows - 1
    var offset: Int64 = 0
    for rank in range(key_n):
        let column = order[rank]
        for row in range(column_lengths[column]):
            column_data[column * 256 + row] = UInt8(input[3 + offset])
            offset += 1
    for row in range(rows):
        for column in range(key_n):
            if row < column_lengths[column]:
                output[written] = column_data[column * 256 + row]
                written += 1
    return written
