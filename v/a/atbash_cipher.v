module atbash_cipher

// Apply the case-preserving Atbash mapping to a 7-bit ASCII byte sequence.
@[export: 'atbash_cipher']
pub fn atbash_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 66 { return -1 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        if value < 0 || value > 127 { return -1 }
    }
    if output_capacity < length { return -2 }
    for index := usize(0); index < length; index++ {
        value := unsafe { input[index] }
        mut mapped := value
        if value >= 65 && value <= 90 {
            mapped = 155 - value
        } else if value >= 97 && value <= 122 {
            mapped = 219 - value
        }
        unsafe { output[index] = u8(mapped) }
    }
    return i64(length)
}
