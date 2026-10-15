package quartile

import "core:c"

store_i64_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
quartile :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 11 || input[0] < 1 || input[0] > 10 do return -1
    count := int(input[0])
    if int(length) != count + 1 do return -1
    values: [10]i64
    for index := 0; index < count; index += 1 {
        if input[index + 1] < 0 || input[index + 1] > 99 do return -1
        values[index] = input[index + 1]
    }
    for i := 0; i < count; i += 1 {
        for j := 0; j < count; j += 1 {
            if values[i] < values[j] { temporary := values[i]; values[i] = values[j]; values[j] = temporary }
        }
    }
    q1 := values[count / 4]
    q3 := values[(3 * count) / 4]
    required := (count + 4) * 8
    if output == nil || output_capacity < c.size_t(required) do return -2
    store_i64_le(output, 0, i64(count))
    for index := 0; index < count; index += 1 { store_i64_le(output, 8 * (index + 1), values[index]) }
    store_i64_le(output, 8 * (count + 1), q1)
    store_i64_le(output, 8 * (count + 2), q3)
    store_i64_le(output, 8 * (count + 3), q3 - q1)
    return i64(required)
}
