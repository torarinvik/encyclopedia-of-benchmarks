package raita_search

import "core:c"

RAITA_MAX_TEXT :: 255
RAITA_MAX_PATTERN :: 64
RAITA_MAX_FRAME :: 322

raita_store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
raita_search :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > RAITA_MAX_FRAME do return -1
    if input[0] < 0 || input[0] > RAITA_MAX_TEXT || input[1] < 1 || input[1] > RAITA_MAX_PATTERN do return -1
    n := int(input[0])
    m := int(input[1])
    if int(length) != 2 + n + m do return -1
    for i := 0; i < n + m; i += 1 {
        if input[2 + i] < 0 || input[2 + i] > 127 do return -1
    }

    positions: [255]i64 = {}
    match_count := 0
    if m <= n {
        shifts: [128]int
        for byte := 0; byte < 128; byte += 1 do shifts[byte] = m
        for i := 0; i < m - 1; i += 1 do shifts[int(input[2 + n + i])] = m - i - 1
        middle := m / 2
        alignment := 0
        for alignment <= n - m {
            last := int(input[2 + alignment + m - 1])
            matches := input[2 + n + m - 1] == i64(last)
            if matches do matches = input[2 + n] == input[2 + alignment]
            if matches do matches = input[2 + n + middle] == input[2 + alignment + middle]
            if matches {
                index := 1
                for index + 1 < m && matches {
                    if input[2 + n + index] != input[2 + alignment + index] do matches = false
                    index += 1
                }
                if matches {
                    positions[match_count] = i64(alignment)
                    match_count += 1
                }
            }
            alignment += shifts[last]
        }
    }
    output_bytes := c.size_t(match_count * 8)
    if output == nil || output_capacity < output_bytes do return -2
    for i := 0; i < match_count; i += 1 do raita_store_i64_le(output, i * 8, positions[i])
    return i64(output_bytes)
}
