package count_min_sketch_width_one_collision

import "core:c"

put_i64_le :: proc(value: i64, output: [^]u8, offset: usize) {
    bits := transmute(u64)value
    for byte: usize = 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
count_min_sketch_width_one_collision :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 513 do return -1
    count_value := input[0]
    if count_value < 0 || count_value > 256 do return -1
    count := usize(count_value)
    if length != 1 + count * 2 do return -1
    queries: usize = 0
    for i: usize = 0; i < count; i += 1 {
        operation, key := input[1 + 2 * i], input[2 + 2 * i]
        if (operation != 0 && operation != 1) || key < -1_000_000 || key > 1_000_000 do return -1
        if operation == 1 do queries += 1
    }
    required := queries * 8
    if capacity < required || (required > 0 && output == nil) do return -2
    inserts: i64 = 0
    output_offset: usize = 0
    for i: usize = 0; i < count; i += 1 {
        if input[1 + 2 * i] == 0 { inserts += 1 }
        else { put_i64_le(inserts, output, output_offset); output_offset += 8 }
    }
    return i64(required)
}
