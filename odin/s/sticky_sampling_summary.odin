package sticky_sampling_summary

import "core:c"

put_word :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for j := 0; j < 8; j += 1 { output[offset+j] = u8(bits & 255); bits >>= 8 }
}

@(export)
sticky_sampling_summary :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 323 || input[0] < 1 || input[0] > 8 ||
       input[1] < 0 || input[1] > 64 || input[2] < 0 || input[2] > 256 { return -1 }
    t, n, k := int(input[0]), int(input[1]), int(input[2])
    if int(length) != 3+n+k { return -1 }
    for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] > 15 { return -1 } }
    for i := 0; i < k; i += 1 { if input[3+n+i] < 0 || input[3+n+i] > 255 { return -1 } }
    counts: [16]i64
    cursor, rate, phase_end := 0, 1, 2*t
    for i := 0; i < n; i += 1 {
        if i == phase_end {
            rate *= 2; phase_end += rate*t
            for item := 0; item < 16; item += 1 {
                for counts[item] != 0 {
                    if cursor == k { return -1 }
                    draw := input[3+n+cursor]; cursor += 1
                    if draw%2 == 1 { break }
                    counts[item] -= 1
                }
            }
        }
        item := int(input[3+i])
        if counts[item] != 0 { counts[item] += 1 } else {
            if cursor == k { return -1 }
            draw := int(input[3+n+cursor]); cursor += 1
            if draw%rate == 0 { counts[item] = 1 }
        }
    }
    if cursor != k { return -1 }
    active := 0
    for count in counts { if count != 0 { active += 1 } }
    bytes := 8+16*active
    if output == nil || capacity < c.size_t(bytes) { return -2 }
    put_word(output, 0, i64(active))
    offset := 8
    for item := 0; item < 16; item += 1 {
        if counts[item] != 0 {
            put_word(output, offset, i64(item)); put_word(output, offset+8, counts[item]); offset += 16
        }
    }
    return i64(bytes)
}
