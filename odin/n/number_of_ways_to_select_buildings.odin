package number_of_ways_to_select_buildings

import "core:c"

MAX_LENGTH :: 4096

@(export)
number_of_ways_to_select_buildings :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length == 0 do return 0
    if values == nil || length > MAX_LENGTH do return -1
    different_bits, ways: u64
    zeros, ones, zero_one, one_zero: u32
    for index := 0; index < int(length); index += 1 {
        value := u64(values[index]) ~ 48
        different_bits |= value
        is_one := (value & 1) != 0
        ways += u64(one_zero if is_one else zero_one)
        zero_one += zeros if is_one else 0
        one_zero += 0 if is_one else ones
        zeros += 0 if is_one else 1
        ones += 1 if is_one else 0
    }
    if different_bits > 1 do return -1
    return i64(ways)
}
