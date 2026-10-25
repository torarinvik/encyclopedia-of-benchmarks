package tsvc_indexed_gather_scatter

import "core:c"

MAX_N :: 16
MAX_INPUT_LENGTH :: 2 + 5 * MAX_N
MAX_OPERAND :: i64(1_000_000)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
    }
}

bounded_operand :: proc "contextless" (value: i64) -> bool {
    return value >= -MAX_OPERAND && value <= MAX_OPERAND
}

@(export)
tsvc_indexed_gather_scatter :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 6 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    mode, n_raw := input[0], input[1]
    if (mode != 491 && mode != 4113) || n_raw < 1 || n_raw > MAX_N do return -1
    n := int(n_raw)
    arrays_per_index := 4
    if mode == 491 do arrays_per_index = 5
    if int(length) != 2 + arrays_per_index * n do return -1

    index_start := 2
    a_start := index_start + n
    b_start := a_start + n
    c_start := b_start + n
    d_start := c_start + n
    var state: [MAX_N]i64
    for i := 0; i < n; i += 1 {
        index := input[index_start + i]
        if index < 0 || index >= n_raw do return -1
        state[i] = input[a_start + i]
        if !bounded_operand(input[b_start + i]) || !bounded_operand(input[c_start + i]) do return -1
        if mode == 491 && !bounded_operand(input[d_start + i]) do return -1
    }
    if output == nil || output_capacity < c.size_t(8 * n) do return -2

    for i := 0; i < n; i += 1 {
        index := int(input[index_start + i])
        if mode == 491 {
            state[index] = input[b_start + i] + input[c_start + i] * input[d_start + i]
        } else {
            state[index] = input[b_start + index] + input[c_start + i]
        }
    }
    for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, state[i]) }
    return i64(n)
}
