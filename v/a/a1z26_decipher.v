module a1z26_decipher

// Decode one-based alphabet positions as lowercase ASCII letters.
@[export: 'a1z26_decipher']
pub fn a1z26_decipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 66 { return -1 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        if value < 1 || value > 26 { return -1 }
    }
    if output_capacity < length { return -2 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        unsafe { output[index] = u8(96 + value) }
    }
    return i64(length)
}
