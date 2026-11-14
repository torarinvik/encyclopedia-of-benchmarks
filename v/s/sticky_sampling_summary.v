module sticky_sampling_summary

fn put_word(output &u8, offset int, value i64) {
    mut bits := u64(value)
    for j in 0 .. 8 {
        unsafe { output[offset+j] = u8(bits & 255) }
        bits >>= 8
    }
}

@[export: 'sticky_sampling_summary']
pub fn sticky_sampling_summary(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 3 || length > 323 { return -1 }
    tv := unsafe { input[0] }
    nv := unsafe { input[1] }
    kv := unsafe { input[2] }
    if tv < 1 || tv > 8 || nv < 0 || nv > 64 || kv < 0 || kv > 256 { return -1 }
    t := int(tv)
    n := int(nv)
    k := int(kv)
    if length != usize(3+n+k) { return -1 }
    for i in 0 .. n {
        value := unsafe { input[3+i] }
        if value < 0 || value > 15 { return -1 }
    }
    for i in 0 .. k {
        value := unsafe { input[3+n+i] }
        if value < 0 || value > 255 { return -1 }
    }
    mut counts := [16]i64{}
    mut cursor := 0
    mut rate := 1
    mut phase_end := 2*t
    for i in 0 .. n {
        if i == phase_end {
            rate *= 2
            phase_end += rate*t
            for item in 0 .. 16 {
                for counts[item] != 0 {
                    if cursor == k { return -1 }
                    draw := unsafe { input[3+n+cursor] }
                    cursor++
                    if draw%2 == 1 { break }
                    counts[item]--
                }
            }
        }
        item := int(unsafe { input[3+i] })
        if counts[item] != 0 { counts[item]++ } else {
            if cursor == k { return -1 }
            draw := int(unsafe { input[3+n+cursor] })
            cursor++
            if draw%rate == 0 { counts[item] = 1 }
        }
    }
    if cursor != k { return -1 }
    mut active := 0
    for count in counts { if count != 0 { active++ } }
    bytes := 8+16*active
    if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
    put_word(output, 0, i64(active))
    mut offset := 8
    for item in 0 .. 16 {
        if counts[item] != 0 {
            put_word(output, offset, i64(item))
            put_word(output, offset+8, counts[item])
            offset += 16
        }
    }
    return i64(bytes)
}
