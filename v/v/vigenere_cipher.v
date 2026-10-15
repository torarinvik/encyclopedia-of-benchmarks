module vigenere_cipher

// Encrypt ASCII text with a repeating, case-insensitive Vigenere key.
@[export: 'vigenere_cipher']
pub fn vigenere_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 2 || length > 66 { return -1 }
    mut separator := usize(0)
    for separator < length && unsafe { input[separator] != 0 } { separator++ }
    if separator == length || separator + 1 == length { return -1 }
    key_length := length - separator - 1
    for index := usize(0); index < separator; index++ {
        value := unsafe { input[index] }
        if value < 1 || value > 127 { return -1 }
    }
    for index := usize(0); index < key_length; index++ {
        value := unsafe { input[separator + 1 + index] }
        if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) { return -1 }
    }
    if output_capacity < separator { return -2 }

    mut key_index := usize(0)
    for index := usize(0); index < separator; index++ {
        value := unsafe { input[index] }
        mut mapped := value
        if value >= 65 && value <= 90 {
            mut key_value := unsafe { input[separator + 1 + key_index] }
            if key_value >= 97 { key_value -= 32 }
            mapped = 65 + (value - 65 + key_value - 65) % 26
            key_index = (key_index + 1) % key_length
        } else if value >= 97 && value <= 122 {
            mut key_value := unsafe { input[separator + 1 + key_index] }
            if key_value <= 90 { key_value += 32 }
            mapped = 97 + (value - 97 + key_value - 97) % 26
            key_index = (key_index + 1) % key_length
        }
        unsafe { output[index] = u8(mapped) }
    }
    return i64(separator)
}
