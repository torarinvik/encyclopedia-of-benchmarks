package compress

import "core:c"

MAX_LENGTH :: 64
BYTES_PER_VALUE :: 4

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i64) {
    bits := u32(value)
    for byte := 0; byte < BYTES_PER_VALUE; byte += 1 {
        output[position + byte] = u8((bits >> u64(byte * 8)) & 255)
    }
}

@(export)
compress :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_LENGTH + 1) do return -1
    count_value := input[0]
    if count_value < 0 || count_value > MAX_LENGTH || length != 1 + c.size_t(count_value) do return -1
    count := int(count_value)
    for index := 0; index < count; index += 1 {
        value := input[1 + index]
        if value < -2147483648 || value > 2147483647 do return -1
    }

    maximum_bytes := c.size_t(count * BYTES_PER_VALUE)
    if output_capacity < maximum_bytes || (maximum_bytes > 0 && output == nil) do return -2
    result_count := 0
    previous: i64 = 0
    for index := 0; index < count; index += 1 {
        value := input[1 + index]
        if index == 0 || value != previous {
            store_i32_le(output, result_count * BYTES_PER_VALUE, value)
            result_count += 1
        }
        previous = value
    }
    return i64(result_count)
}
