package duval_algorithm

import "core:c"

MAX_LENGTH :: c.size_t(4096)

valid_input :: proc(values: [^]i64, length: c.size_t) -> bool {
    if length > MAX_LENGTH || (length != 0 && values == nil) do return false
    for index: c.size_t = 0; index < length; index += 1 {
        if values[index] < 0 || values[index] > 127 do return false
    }
    return true
}

factor_count :: proc(values: [^]i64, length: c.size_t) -> c.size_t {
    start, count := c.size_t(0), c.size_t(0)
    for start < length {
        end_index, repeat := start + 1, start
        for end_index < length && values[repeat] <= values[end_index] {
            if values[repeat] < values[end_index] do repeat = start
            else do repeat += 1
            end_index += 1
        }
        factor_length := end_index - repeat
        for start <= repeat {
            count += 1
            start += factor_length
        }
    }
    return count
}

store_u32_le :: proc(output: [^]u8, offset, value: c.size_t) {
    packed := u32(value)
    for byte_index: c.size_t = 0; byte_index < 4; byte_index += 1 {
        output[offset + byte_index] = u8((packed >> u32(8 * byte_index)) & 255)
    }
}

write_factors :: proc(values: [^]i64, length: c.size_t, output: [^]u8) {
    start, factor_index := c.size_t(0), c.size_t(0)
    for start < length {
        end_index, repeat := start + 1, start
        for end_index < length && values[repeat] <= values[end_index] {
            if values[repeat] < values[end_index] do repeat = start
            else do repeat += 1
            end_index += 1
        }
        factor_length := end_index - repeat
        for start <= repeat {
            store_u32_le(output, 4 * factor_index, factor_length)
            factor_index += 1
            start += factor_length
        }
    }
}

@(export)
duval_algorithm :: proc "c" (values: [^]i64, length: c.size_t,
                             output: [^]u8, output_capacity: c.size_t) -> i64 {
    if !valid_input(values, length) do return -1
    count := factor_count(values, length)
    required := 4 * count
    if required == 0 do return 0
    if output == nil || output_capacity < required do return -2
    write_factors(values, length, output)
    return i64(count)
}
