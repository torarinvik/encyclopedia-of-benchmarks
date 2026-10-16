package bit_array_count_zero_bits

import "core:c"

@(export)
bit_array_count_zero_bits :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 || (length != 0 && values == nil) do return -1
    zero_count: i64 = 0
    for index := 0; index < int(length); index += 1 {
        if values[index] != 0 && values[index] != 1 do return -1
        if values[index] == 0 do zero_count += 1
    }
    return zero_count
}
