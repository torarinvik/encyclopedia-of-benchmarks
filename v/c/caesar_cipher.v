module caesar_cipher

// Apply a normalized Caesar shift to ASCII letters in a byte sequence.
@[export: 'caesar_cipher']
pub fn caesar_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length == 0 || length > 66 { return -1 }
    text_length := length - 1
    for index := usize(0); index < text_length; index++ {
        value := unsafe { input[index] }
        if value < 0 || value > 127 { return -1 }
    }
    if output_capacity < text_length { return -2 }

    mut shift := unsafe { input[text_length] } % 26
    if shift < 0 { shift += 26 }
    for index := usize(0); index < text_length; index++ {
        value := unsafe { input[index] }
        mut mapped := value
        if value >= 65 && value <= 90 {
            mapped = 65 + (value - 65 + shift) % 26
        } else if value >= 97 && value <= 122 {
            mapped = 97 + (value - 97 + shift) % 26
        }
        unsafe { output[index] = u8(mapped) }
    }
    return i64(text_length)
}
