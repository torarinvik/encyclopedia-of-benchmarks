package tuned_boyer_moore_search

import "core:c"

TUNED_MAX_TEXT :: 255
TUNED_MAX_PATTERN :: 64
TUNED_MAX_FRAME :: 322
TUNED_MAX_PADDED :: 319

tuned_store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
tuned_boyer_moore_search :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > TUNED_MAX_FRAME do return -1
    if input[0] < 0 || input[0] > TUNED_MAX_TEXT || input[1] < 1 || input[1] > TUNED_MAX_PATTERN do return -1
    n := int(input[0])
    m := int(input[1])
    if int(length) != 2 + n + m do return -1
    for i := 0; i < n + m; i += 1 {
        if input[2 + i] < 0 || input[2 + i] > 127 do return -1
    }

    positions: [255]i64 = {}
    match_count := 0
    if m <= n {
        padded: [TUNED_MAX_PADDED]u8 = {}
        shifts: [128]int
        pattern_start := 2 + n
        final_byte := u8(input[pattern_start + m - 1])
        for i := 0; i < n; i += 1 do padded[i] = u8(input[2 + i])
        for i := 0; i < m; i += 1 do padded[n + i] = final_byte
        for byte := 0; byte < 128; byte += 1 do shifts[byte] = m
        for i := 0; i < m - 1; i += 1 do shifts[int(input[pattern_start + i])] = m - i - 1
        final_shift := shifts[int(final_byte)]
        shifts[int(final_byte)] = 0
        alignment := 0
        for alignment < n {
            skip := shifts[int(padded[alignment + m - 1])]
            for skip != 0 {
                alignment += skip; skip = shifts[int(padded[alignment + m - 1])]
                alignment += skip; skip = shifts[int(padded[alignment + m - 1])]
                alignment += skip; skip = shifts[int(padded[alignment + m - 1])]
            }
            prefix_matches := true
            for i := 0; i < m - 1; i += 1 {
                if i64(padded[alignment + i]) != input[pattern_start + i] { prefix_matches = false; break }
            }
            if prefix_matches && alignment < n {
                positions[match_count] = i64(alignment)
                match_count += 1
            }
            alignment += final_shift
        }
    }
    output_bytes := c.size_t(match_count * 8)
    if output == nil || output_capacity < output_bytes do return -2
    for i := 0; i < match_count; i += 1 do tuned_store_i64_le(output, i * 8, positions[i])
    return i64(output_bytes)
}
