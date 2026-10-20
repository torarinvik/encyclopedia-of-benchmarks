package morton_sort

import "core:c"

spread_16 :: proc "contextless" (value_in: u32) -> u32 {
    value := value_in
    value = (value | (value << 8)) & 0x00ff00ff
    value = (value | (value << 4)) & 0x0f0f0f0f
    value = (value | (value << 2)) & 0x33333333
    return (value | (value << 1)) & 0x55555555
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

@(export)
morton_sort :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
                          output_capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 513 do return -1
    raw_count := input[0]
    if raw_count < 1 || raw_count > 256 do return -1
    count := int(raw_count)
    if length != c.size_t(1 + 2 * count) do return -1
    keys: [256]u32
    order: [256]int
    for index := 0; index < count; index += 1 {
        x, y := input[1 + 2 * index], input[2 + 2 * index]
        if x < 0 || x > 65535 || y < 0 || y > 65535 do return -1
        keys[index] = spread_16(u32(x)) | (spread_16(u32(y)) << 1)
        order[index] = index
    }
    bytes := count * 8
    if output == nil || output_capacity < c.size_t(bytes) do return -2
    for index := 1; index < count; index += 1 {
        current := order[index]
        position := index
        for position > 0 && (keys[order[position - 1]] > keys[current] ||
            (keys[order[position - 1]] == keys[current] && order[position - 1] > current)) {
            order[position] = order[position - 1]
            position -= 1
        }
        order[position] = current
    }
    for index := 0; index < count; index += 1 { store_i64_le(output, index * 8, i64(order[index])) }
    return i64(bytes)
}
