module a1z26_cipher

// Encode ASCII letters as their one-based alphabet positions.
@[export: 'a1z26_cipher']
pub fn a1z26_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 66 { return -1 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
    }
    if output_capacity < length { return -2 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        mapped := if value >= 97 { value - 96 } else { value - 64 }
        unsafe { output[index] = u8(mapped) }
    }
    return i64(length)
}
