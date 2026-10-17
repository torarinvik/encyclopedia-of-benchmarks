package least_recently_used

import "core:c"

@(export)
least_recently_used :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 66 do return -1
    capacity_value := input[0]
    reference_count_value := input[1]
    if capacity_value < 1 || capacity_value > 16 || reference_count_value < 0 || reference_count_value > 64 do return -1
    cache_capacity := int(capacity_value)
    references := int(reference_count_value)
    if length != c.size_t(2 + references) do return -1
    for i := 0; i < references; i += 1 {
        key := input[2 + i]
        if key < -2_147_483_648 || key > 2_147_483_647 do return -1
    }

    keys: [16]i64 = {}
    count := 0
    for i := 0; i < references; i += 1 {
        key := input[2 + i]
        found := count
        for j := 0; j < count; j += 1 { if keys[j] == key { found = j; break } }
        if found < count {
            for j := found; j + 1 < count; j += 1 { keys[j] = keys[j + 1] }
            count -= 1
        } else if count == cache_capacity do count -= 1
        for j := count; j > 0; j -= 1 { keys[j] = keys[j - 1] }
        keys[0] = key
        count += 1
    }

    elements := count + 1
    required := elements * 8
    if output == nil || output_capacity < c.size_t(required) do return -2
    size_bits := u64(count)
    for byte := 0; byte < 8; byte += 1 { output[byte] = u8((size_bits >> (8 * byte)) & 255) }
    for i := 0; i < count; i += 1 {
        bits := u64(keys[i])
        for byte := 0; byte < 8; byte += 1 { output[(i + 1) * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
    }
    return i64(elements)
}
