package constant_intervals

import "core:c"

MAX_N :: 256

Interval_State :: struct {
    output: [^]u8,
    count: int,
    last_hi: int,
    last_value: i32,
    has_last: bool,
}

value_at :: proc "contextless" (index: int, step, offset, divisor: i64) -> i32 {
    return i32((step * i64(index) + offset) / divisor)
}

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i32) {
    bits := u32(value)
    for byte := 0; byte < 4; byte += 1 {
        output[position + byte] = u8((bits >> u32(byte * 8)) & 255)
    }
}

append_interval :: proc "contextless" (state: ^Interval_State, lo, hi: int, value: i32) {
    if state.has_last && state.last_hi == lo && state.last_value == value {
        store_i32_le(state.output, (state.count - 1) * 12 + 4, i32(hi))
    } else {
        position := state.count * 12
        store_i32_le(state.output, position, i32(lo))
        store_i32_le(state.output, position + 4, i32(hi))
        store_i32_le(state.output, position + 8, value)
        state.count += 1
    }
    state.last_hi = hi
    state.last_value = value
    state.has_last = true
}

visit_range :: proc "contextless" (lo, hi: int, step, offset, divisor: i64,
                                   state: ^Interval_State) {
    first := value_at(lo, step, offset, divisor)
    last := value_at(hi - 1, step, offset, divisor)
    if first == last || hi - lo == 1 {
        append_interval(state, lo, hi, first)
        return
    }
    mid := lo + (hi - lo) / 2
    visit_range(lo, mid, step, offset, divisor, state)
    visit_range(mid, hi, step, offset, divisor, state)
}

@(export)
constant_intervals :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length != 4 do return -1
    n_value, step, offset, divisor := input[0], input[1], input[2], input[3]
    if n_value < 0 || n_value > MAX_N || step < 0 || step > 65535
        || offset < 0 || offset > 65535 || divisor < 1 || divisor > 65535 do return -1
    n := int(n_value)
    maximum_bytes := c.size_t(n * 12)
    if output_capacity < maximum_bytes || (maximum_bytes > 0 && output == nil) do return -2
    if n == 0 do return 0
    state := Interval_State{output = output}
    visit_range(0, n, step, offset, divisor, &state)
    return i64(state.count)
}
