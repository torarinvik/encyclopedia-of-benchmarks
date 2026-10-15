package plus_one

import "core:c"

// Increment decimal digits and write their ASCII representation.
@(export)
plus_one :: proc "c" (digits: [^]i64, length: c.size_t, output: [^]u8,
    output_capacity: c.size_t) -> i64 {
    if length > 256 do return -1
    all_nines := true
    for index := 0; index < int(length); index += 1 {
        if digits[index] < 0 || digits[index] > 9 do return -1
        if digits[index] != 9 do all_nines = false
    }
    if length > 1 && digits[0] == 0 do return -1
    output_length := length
    if length == 0 || all_nines do output_length += 1
    if output_capacity < output_length do return -2
    if length == 0 || all_nines {
        output[0] = u8('1')
        for index := 1; index < int(output_length); index += 1 { output[index] = u8('0') }
        return i64(output_length)
    }
    for index := 0; index < int(length); index += 1 { output[index] = u8('0' + digits[index]) }
    index := int(length)
    for index > 0 {
        index -= 1
        if digits[index] == 9 do output[index] = u8('0')
        else {
            output[index] += 1
            break
        }
    }
    return i64(output_length)
}
