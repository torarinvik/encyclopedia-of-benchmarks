from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_SIDE = 12
alias MAX_CELLS = MAX_SIDE * MAX_SIDE
alias MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * MAX_CELLS + 1

fn sample_code(input: UnsafePointer[Int64, ImmutAnyOrigin], base: Int,
        side: Int, row: Int, column: Int, count: Int, stride: Int) -> Int:
    var code = 0
    for offset in range(count):
        let at = base + row * side + column + offset * stride
        code = 4 * code + Int(input[at])
    return code

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
        value: Int64) -> None:
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("two_dimensional_optimal_expected_matching")
fn two_dimensional_optimal_expected_matching(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_PARSEABLE_INPUT_LENGTH):
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_SIDE or m_value < 1 or m_value > n_value:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let text_size = n * n
    let pattern_size = m * m
    if length != c_size_t(2 + text_size + pattern_size):
        return -1
    let pattern_base = 2 + text_size
    for index in range(text_size + pattern_size):
        let value = input[2 + index]
        if value < 0 or value > 3:
            return -1

    var q = 1
    var code_capacity = 4
    while code_capacity < pattern_size:
        q += 1
        code_capacity *= 4
    let stride = m // q
    let final_offset = (q - 1) * stride
    var heads = InlineArray[Int16, 256](fill=Int16(-1))
    var next_address = InlineArray[Int16, 144](fill=Int16(-1))
    var address_row = InlineArray[UInt8, 144](fill=0)
    var address_column = InlineArray[UInt8, 144](fill=0)
    var address_count = 0
    for row in range(m):
        for residue in range(stride):
            let code = sample_code(input, pattern_base, m, row, residue, q, stride)
            address_row[address_count] = UInt8(row)
            address_column[address_count] = UInt8(residue)
            next_address[address_count] = heads[code]
            heads[code] = Int16(address_count)
            address_count += 1

    var tested = InlineArray[Bool, 144](fill=False)
    var matched = InlineArray[Bool, 144](fill=False)
    let row_starts = n - m + 1
    let column_starts = n - m + 1
    for text_row in range(0, n, m):
        for text_column in range(0, n - final_offset, stride):
            let code = sample_code(input, 2, n, text_row, text_column, q, stride)
            var address = heads[code]
            while address >= 0:
                let slot = Int(address)
                let candidate_row = text_row - Int(address_row[slot])
                let candidate_column = text_column - Int(address_column[slot])
                if candidate_row >= 0 and candidate_column >= 0 and candidate_row < row_starts and candidate_column < column_starts:
                    let candidate = candidate_row * n + candidate_column
                    if not tested[candidate]:
                        tested[candidate] = True
                        var equal = True
                        for pattern_row in range(m):
                            for pattern_column in range(m):
                                let text_at = 2 + (candidate_row + pattern_row) * n + candidate_column + pattern_column
                                let pattern_at = pattern_base + pattern_row * m + pattern_column
                                if input[text_at] != input[pattern_at]:
                                    equal = False
                                    break
                            if not equal:
                                break
                        matched[candidate] = equal
                address = next_address[slot]

    var match_count = 0
    for row in range(row_starts):
        for column in range(column_starts):
            if matched[row * n + column]:
                match_count += 1
    let output_bytes = 8 * (1 + 2 * match_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    put_i64_le(output, 0, Int64(match_count))
    var output_word = 1
    for row in range(row_starts):
        for column in range(column_starts):
            if matched[row * n + column]:
                put_i64_le(output, 8 * output_word, Int64(row))
                output_word += 1
                put_i64_le(output, 8 * output_word, Int64(column))
                output_word += 1
    return Int64(output_bytes)
