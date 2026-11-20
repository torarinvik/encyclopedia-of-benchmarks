package numbers_with_prime_divisor_count_not_two

import "core:c"

MAX_INPUT_LENGTH :: 2
MAX_LIMIT :: 1000

is_prime_count :: proc "contextless" (value: u16) -> bool {
    if value < 2 do return false
    for divisor := u16(2); divisor <= value / divisor; divisor += 1 {
        if value % divisor == 0 do return false
    }
    return true
}

store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
numbers_with_prime_divisor_count_not_two :: proc "c" (input: [^]i64,
    length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if length != 1 || input[0] < 1 || input[0] > MAX_LIMIT do return -1

    limit := int(input[0])
    divisor_counts: [MAX_LIMIT]u16
    for divisor := 1; divisor < limit; divisor += 1 {
        for multiple := divisor; multiple < limit; multiple += divisor {
            divisor_counts[multiple] += 1
        }
    }
    selected_count := 0
    for n := 1; n < limit; n += 1 {
        count := divisor_counts[n]
        if count != 2 && is_prime_count(count) do selected_count += 1
    }
    output_bytes := selected_count * 8
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    output_index := 0
    for n := 1; n < limit; n += 1 {
        count := divisor_counts[n]
        if count != 2 && is_prime_count(count) {
            store_i64(output, output_index * 8, i64(n))
            output_index += 1
        }
    }
    return i64(output_bytes)
}
