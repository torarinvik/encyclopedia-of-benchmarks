// Uncompiled monotone-cursor Prüfer decoder draft.
fn pdl_write(mut output &u8, offset int, value int) {
    mut bits := u64(value)
    for i in 0 .. 8 { unsafe { output[offset+i] = u8(bits & 255) }; bits >>= 8 }
}
@[export: 'prufer_decode_linear']
pub fn prufer_decode_linear(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if length < 1 || length > 4096 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nv := input[0]
        if nv < 2 || nv > 4096 || length != usize(nv-1) { return -1 }
        n := int(nv)
        mut count := [4096]int{}
        for i in 1 .. int(length) {
            if input[i] < 0 || input[i] >= nv { return -1 }
            count[int(input[i])]++
        }
        needed := 16*(n-1)
        if output == nil || capacity < usize(needed) { return -2 }
        mut cursor := n-1
        for count[cursor] != 0 { cursor-- }
        mut leaf := cursor
        for i in 1 .. int(length) {
            v := int(input[i])
            pdl_write(mut output, 16*(i-1), leaf); pdl_write(mut output, 16*(i-1)+8, v)
            count[leaf] = -1; count[v]--
            if count[v] == 0 && v > cursor { leaf = v } else {
                cursor--
                for count[cursor] != 0 { cursor-- }
                leaf = cursor
            }
        }
        mut other := 0
        for other == leaf || count[other] != 0 { other++ }
        pdl_write(mut output, 16*(n-2), leaf); pdl_write(mut output, 16*(n-2)+8, other)
        return i64(needed)
    }
}
