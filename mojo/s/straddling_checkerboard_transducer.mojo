from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INPUT: Int = 97
comptime MAX_TEXT: Int = 64
comptime BOARD_SIZE: Int = 30
comptime MAX_OUTPUT: Int = 128

fn parse_board(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
               hole_a: UnsafePointer[Int, MutAnyOrigin],
               hole_b: UnsafePointer[Int, MutAnyOrigin],
               text_length: UnsafePointer[Int, MutAnyOrigin],
               mode: UnsafePointer[Int64, MutAnyOrigin]) -> Bool:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 32 or length > MAX_INPUT:
        return False
    mode[] = input[0]
    if mode[] != 0 and mode[] != 1:
        return False
    var holes = 0
    for position in range(BOARD_SIZE):
        let value = input[1 + position]
        if position < 10 and value == 0:
            if holes == 0:
                hole_a[] = position
            elif holes == 1:
                hole_b[] = position
            holes += 1
            continue
        if value < 32 or value > 126:
            return False
        for prior in range(position):
            if input[1 + prior] == value:
                return False
    if holes != 2:
        return False
    let count = input[31]
    if count < 0 or count > MAX_TEXT:
        return False
    text_length[] = Int(count)
    return length == c_size_t(32 + text_length[])

fn find_symbol(input: UnsafePointer[Int64, ImmutAnyOrigin], value: Int64) -> Int:
    for position in range(BOARD_SIZE):
        if input[1 + position] != 0 and input[1 + position] == value:
            return position
    return -1

fn measure_decode(input: UnsafePointer[Int64, ImmutAnyOrigin], text_length: Int,
                  hole_a: Int, hole_b: Int, result_length: UnsafePointer[Int, MutAnyOrigin]) -> Bool:
    var index = 0
    while index < text_length:
        let value = input[32 + index]
        if value < Int64(ord('0')) or value > Int64(ord('9')):
            return False
        let column = Int(value - Int64(ord('0')))
        if input[1 + column] != 0:
            result_length[] += 1
            index += 1
            continue
        if (column != hole_a and column != hole_b) or index + 1 >= text_length:
            return False
        let next = input[32 + index + 1]
        if next < Int64(ord('0')) or next > Int64(ord('9')):
            return False
        result_length[] += 1
        index += 2
    return True

@export("straddling_checkerboard_transducer")
fn straddling_checkerboard_transducer(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    var hole_a = -1
    var hole_b = -1
    var text_length = 0
    var mode: Int64 = -1
    if not parse_board(input, length, &hole_a, &hole_b, &text_length, &mode):
        return -1

    var result_length = 0
    if mode == 0:
        for index in range(text_length):
            let position = find_symbol(input, input[32 + index])
            if position < 0:
                return -1
            result_length += 1 if position < 10 else 2
    elif not measure_decode(input, text_length, hole_a, hole_b, &result_length):
        return -1
    if result_length > MAX_OUTPUT:
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(result_length):
        return -2

    if mode == 0:
        var out = 0
        for index in range(text_length):
            let position = find_symbol(input, input[32 + index])
            if position < 10:
                output[out] = UInt8(ord('0') + position)
                out += 1
            else:
                let row_digit = hole_a if position < 20 else hole_b
                output[out] = UInt8(ord('0') + row_digit)
                output[out + 1] = UInt8(ord('0') + position % 10)
                out += 2
    else:
        var index = 0
        var out = 0
        while index < text_length:
            let column = Int(input[32 + index] - Int64(ord('0')))
            if input[1 + column] != 0:
                output[out] = UInt8(input[1 + column])
                index += 1
            else:
                let row = 1 if column == hole_a else 2
                let next_column = Int(input[32 + index + 1] - Int64(ord('0')))
                output[out] = UInt8(input[1 + row * 10 + next_column])
                index += 2
            out += 1
    return Int64(result_length)
