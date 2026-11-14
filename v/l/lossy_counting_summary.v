module lossy_counting_summary

fn put_word(output &u8, offset int, value i64) {
    mut bits := u64(value)
    for j in 0 .. 8 {
        unsafe { output[offset+j] = u8(bits & 255) }
        bits >>= 8
    }
}

@[export: 'lossy_counting_summary']
pub fn lossy_counting_summary(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 66 { return -1 }
    wv := unsafe { input[0] }
    nv := unsafe { input[1] }
    if wv < 2 || wv > 16 || nv < 0 || nv > 64 { return -1 }
    width := int(wv)
    n := int(nv)
    if length != usize(2+n) { return -1 }
    for i in 0 .. n {
        item := unsafe { input[2+i] }
        if item < 0 || item > 15 { return -1 }
    }
    mut count := [16]i64{}
    mut error_count := [16]i64{}
    for i in 0 .. n {
        item := int(unsafe { input[2+i] })
        bucket := i64(i/width+1)
        if count[item] == 0 { error_count[item] = bucket-1 }
        count[item]++
        if (i+1)%width == 0 {
            for j in 0 .. 16 {
                if count[j] != 0 && count[j]+error_count[j] <= bucket { count[j] = 0; error_count[j] = 0 }
            }
        }
    }
    mut active := 0
    for i in 0 .. 16 { if count[i] != 0 { active++ } }
    bytes := 8+24*active
    if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
    put_word(output, 0, i64(active))
    mut offset := 8
    for i in 0 .. 16 {
        if count[i] != 0 {
            put_word(output, offset, i64(i))
            put_word(output, offset+8, count[i])
            put_word(output, offset+16, error_count[i])
            offset += 24
        }
    }
    return i64(bytes)
}
