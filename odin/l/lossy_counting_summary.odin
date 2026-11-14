package lossy_counting_summary

import "core:c"

put_word :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for j := 0; j < 8; j += 1 { output[offset+j] = u8(bits & 255); bits >>= 8 }
}

@(export)
lossy_counting_summary :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 66 || input[0] < 2 || input[0] > 16 || input[1] < 0 || input[1] > 64 { return -1 }
    width, n := int(input[0]), int(input[1])
    if int(length) != 2+n { return -1 }
    for i := 0; i < n; i += 1 { if input[2+i] < 0 || input[2+i] > 15 { return -1 } }
    count, error: [16]i64
    for i := 0; i < n; i += 1 {
        item := int(input[2+i])
        bucket := i64(i/width+1)
        if count[item] == 0 { error[item] = bucket-1 }
        count[item] += 1
        if (i+1)%width == 0 {
            for j := 0; j < 16; j += 1 {
                if count[j] != 0 && count[j]+error[j] <= bucket { count[j] = 0; error[j] = 0 }
            }
        }
    }
    active := 0
    for i := 0; i < 16; i += 1 { if count[i] != 0 { active += 1 } }
    bytes := 8+24*active
    if output == nil || capacity < c.size_t(bytes) { return -2 }
    put_word(output, 0, i64(active))
    offset := 8
    for i := 0; i < 16; i += 1 {
        if count[i] != 0 {
            put_word(output, offset, i64(i))
            put_word(output, offset+8, count[i])
            put_word(output, offset+16, error[i])
            offset += 24
        }
    }
    return i64(bytes)
}
