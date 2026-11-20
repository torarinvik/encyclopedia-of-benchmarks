// Uncompiled indexed Calkin–Wilf fraction draft.
@[export: 'calkin_wilf_index']
pub fn calkin_wilf_index(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if length != 1 { return -1 }
    unsafe {
        if input == nil { return -1 }
        raw := input[0]
        if raw < 1 || raw >= (i64(1) << 62) { return -1 }
        if output == nil || capacity < 16 { return -2 }
        index := u64(raw)
        mut high := u64(1)
        for high <= index / 2 { high *= 2 }
        mut numerator := u64(1)
        mut denominator := u64(1)
        high /= 2
        for high != 0 {
            if (index & high) != 0 { numerator += denominator } else { denominator += numerator }
            high /= 2
        }
        for i in 0 .. 8 {
            output[i] = u8((numerator >> (8*i)) & 255)
            output[i+8] = u8((denominator >> (8*i)) & 255)
        }
        return 16
    }
}
