package smith_string_search

import "core:c"

SMITH_MAX_TEXT :: 255
SMITH_MAX_PATTERN :: 64
SMITH_MAX_FRAME :: 322

smith_store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
smith_string_search :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > SMITH_MAX_FRAME do return -1
    if input[0] < 0 || input[0] > SMITH_MAX_TEXT || input[1] < 1 || input[1] > SMITH_MAX_PATTERN do return -1
    n := int(input[0])
    m := int(input[1])
    if int(length) != 2 + n + m do return -1
    for i := 0; i < n + m; i += 1 {
        if input[2 + i] < 0 || input[2 + i] > 127 do return -1
    }

    positions: [255]i64 = {}
    match_count := 0
    if m <= n {
        pattern_start := 2 + n
        horspool: [128]int
        quick_search: [128]int
        for byte := 0; byte < 128; byte += 1 {
            horspool[byte] = m
            quick_search[byte] = m + 1
        }
        for i := 0; i < m - 1; i += 1 do horspool[int(input[pattern_start + i])] = m - i - 1
        for i := 0; i < m; i += 1 do quick_search[int(input[pattern_start + i])] = m - i

        alignment := 0
        last_alignment := n - m
        for alignment <= last_alignment {
            matches := true
            for i := 0; i < m; i += 1 {
                if input[pattern_start + i] != input[2 + alignment + i] { matches = false; break }
            }
            if matches {
                positions[match_count] = i64(alignment)
                match_count += 1
            }
            end_byte := int(input[2 + alignment + m - 1])
            lookahead := alignment + m
            quick_shift := m + 1
            if lookahead < n do quick_shift = quick_search[int(input[2 + lookahead])]
            end_shift := horspool[end_byte]
            if end_shift > quick_shift { alignment += end_shift } else { alignment += quick_shift }
        }
    }
    output_bytes := c.size_t(match_count * 8)
    if output == nil || output_capacity < output_bytes do return -2
    for i := 0; i < match_count; i += 1 do smith_store_i64_le(output, i * 8, positions[i])
    return i64(output_bytes)
}
