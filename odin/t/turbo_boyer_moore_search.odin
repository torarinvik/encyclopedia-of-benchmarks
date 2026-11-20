package turbo_boyer_moore_search

import "core:c"

TB_MAX_TEXT :: 255
TB_MAX_PATTERN :: 64
TB_MAX_FRAME :: 322

tb_store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

tb_good_suffix :: proc(pattern: [^]i64, length: int, shifts: [^]int) {
    suffix: [64]int = {}
    suffix[length - 1] = length
    g := length - 1
    f := 0
    for index := length - 2; index >= 0; index -= 1 {
        if index > g && suffix[index + length - 1 - f] < index - g {
            suffix[index] = suffix[index + length - 1 - f]
        } else {
            if index < g do g = index
            f = index
            for g >= 0 && pattern[g] == pattern[g + length - 1 - f] { g -= 1 }
            suffix[index] = f - g
        }
    }
    for index := 0; index < length; index += 1 do shifts[index] = length
    border := 0
    for index := length - 1; index >= 0; index -= 1 {
        if suffix[index] == index + 1 {
            for border < length - 1 - index {
                if shifts[border] == length do shifts[border] = length - 1 - index
                border += 1
            }
        }
    }
    for index := 0; index < length - 1; index += 1 {
        shifts[length - 1 - suffix[index]] = length - 1 - index
    }
}

@(export)
turbo_boyer_moore_search :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > TB_MAX_FRAME do return -1
    if input[0] < 0 || input[0] > TB_MAX_TEXT || input[1] < 1 || input[1] > TB_MAX_PATTERN do return -1
    n := int(input[0])
    m := int(input[1])
    if int(length) != 2 + n + m do return -1
    for i := 0; i < n + m; i += 1 {
        if input[2 + i] < 0 || input[2 + i] > 127 do return -1
    }

    positions: [255]i64 = {}
    match_count := 0
    if m <= n {
        bad: [128]int
        good: [64]int
        for byte := 0; byte < 128; byte += 1 do bad[byte] = m
        for i := 0; i < m - 1; i += 1 do bad[int(input[2 + n + i])] = m - i - 1
        tb_good_suffix(input + 2 + n, m, &good[0])
        alignment, remembered, shift := 0, 0, m
        for alignment <= n - m {
            index := m - 1
            for index >= 0 && input[2 + n + index] == input[2 + alignment + index] {
                index -= 1
                if remembered != 0 && index == m - 1 - shift do index -= remembered
            }
            if index < 0 {
                positions[match_count] = i64(alignment)
                match_count += 1
                shift = good[0]
                remembered = m - shift
            } else {
                matched := m - 1 - index
                turbo_shift := remembered - matched
                bad_shift := bad[int(input[2 + alignment + index])] - m + 1 + index
                gs := good[index]
                shift = max(turbo_shift, max(bad_shift, gs))
                if shift == gs {
                    remembered = min(m - shift, matched)
                } else {
                    if turbo_shift < bad_shift && shift < remembered + 1 do shift = remembered + 1
                    remembered = 0
                }
            }
            alignment += shift
        }
    }
    output_bytes := c.size_t(match_count * 8)
    if output == nil || output_capacity < output_bytes do return -2
    for i := 0; i < match_count; i += 1 do tb_store_i64_le(output, i * 8, positions[i])
    return i64(output_bytes)
}
