from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias KM_MAX_SIDE = 12
alias KM_MAX_CELLS = KM_MAX_SIDE * KM_MAX_SIDE
alias KM_MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * KM_MAX_CELLS + 1

fn km_sample_code(input: UnsafePointer[Int64, ImmutAnyOrigin], base: Int,
        side: Int, row: Int, column: Int, q: Int, stride: Int) -> Int:
    var code = 0
    for step in range(q):
        let at = base + row * side + column + step * stride
        code = 4 * code + Int(input[at])
    return code

fn km_put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
        value: Int64) -> None:
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("two_dimensional_k_mismatch_linear_templates")
fn two_dimensional_k_mismatch_linear_templates(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(KM_MAX_PARSEABLE_INPUT_LENGTH):
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 3 or n_value > KM_MAX_SIDE or m_value < 3 or m_value > n_value:
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
    var next_address = InlineArray[Int16, KM_MAX_CELLS](fill=0)
    var sample_row = InlineArray[UInt8, KM_MAX_CELLS](fill=0)
    var sample_column = InlineArray[UInt8, KM_MAX_CELLS](fill=0)
    var sample_count = 0
    for row in range(m):
        for residue in range(stride):
            let code = km_sample_code(input, pattern_base, m, row, residue, q, stride)
            sample_row[sample_count] = UInt8(row)
            sample_column[sample_count] = UInt8(residue)
            next_address[sample_count] = heads[code]
            heads[code] = Int16(sample_count)
            sample_count += 1

    var considered = InlineArray[Bool, KM_MAX_CELLS](fill=False)
    var matched = InlineArray[Bool, KM_MAX_CELLS](fill=False)
    let starts = n - m + 1
    for text_row in range(n):
        if text_row % m >= m - 2:
            for text_column in range(0, n - final_offset, stride):
                let code = km_sample_code(input, 2, n, text_row, text_column, q, stride)
                var address = heads[code]
                while address >= 0:
                    let slot = Int(address)
                    let candidate_row = text_row - Int(sample_row[slot])
                    let candidate_column = text_column - Int(sample_column[slot])
                    if candidate_row >= 0 and candidate_column >= 0 and candidate_row < starts and candidate_column < starts:
                        let candidate = candidate_row * n + candidate_column
                        if not considered[candidate]:
                            considered[candidate] = True
                            var mismatches = 0
                            for dr in range(m):
                                for dc in range(m):
                                    let text_at = 2 + (candidate_row + dr) * n + candidate_column + dc
                                    let pattern_at = pattern_base + dr * m + dc
                                    if input[text_at] != input[pattern_at]:
                                        mismatches += 1
                                        if mismatches == 2:
                                            break
                                if mismatches == 2:
                                    break
                            matched[candidate] = mismatches <= 1
                    address = next_address[slot]

    var match_count = 0
    for row in range(starts):
        for column in range(starts):
            if matched[row * n + column]:
                match_count += 1
    let output_bytes = 8 * (1 + 2 * match_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    km_put_i64_le(output, 0, Int64(match_count))
    var word = 1
    for row in range(starts):
        for column in range(starts):
            if matched[row * n + column]:
                km_put_i64_le(output, 8 * word, Int64(row))
                word += 1
                km_put_i64_le(output, 8 * word, Int64(column))
                word += 1
    return Int64(output_bytes)
