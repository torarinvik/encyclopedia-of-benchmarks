package railway_time_conversion

import "core:c"

MAX_INPUT_LENGTH :: 10
PACKED_INPUT_LENGTH :: MAX_INPUT_LENGTH + 1
OUTPUT_LENGTH :: 8

is_digit :: proc(value: i64) -> bool {
    return value >= 48 && value <= 57
}

@(export)
railway_time_conversion :: proc "c" (values: [^]i64, length: c.size_t,
                                      output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length != c.size_t(PACKED_INPUT_LENGTH) ||
        values[0] != i64(MAX_INPUT_LENGTH) do return -1

    if values[3] != 58 || values[6] != 58 ||
        !((values[9] == 65 && values[10] == 77) ||
          (values[9] == 80 && values[10] == 77)) ||
        !is_digit(values[1]) || !is_digit(values[2]) ||
        !is_digit(values[4]) || !is_digit(values[5]) ||
        !is_digit(values[7]) || !is_digit(values[8]) do return -1

    hour := (values[1] - 48) * 10 + values[2] - 48
    minute := (values[4] - 48) * 10 + values[5] - 48
    second := (values[7] - 48) * 10 + values[8] - 48
    if hour < 1 || hour > 12 || minute > 59 || second > 59 do return -1
    if output == nil || output_capacity < c.size_t(OUTPUT_LENGTH) do return -2

    hour24 := hour % 12 + (if values[9] == 80 do 12 else 0)
    output[0] = u8(48 + hour24 / 10)
    output[1] = u8(48 + hour24 % 10)
    output[2] = 58
    output[3] = u8(values[4])
    output[4] = u8(values[5])
    output[5] = 58
    output[6] = u8(values[7])
    output[7] = u8(values[8])
    return i64(OUTPUT_LENGTH)
}
