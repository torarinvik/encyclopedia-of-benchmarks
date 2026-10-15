module gronsfeld_cipher

// Encrypt 7-bit ASCII with a repeating decimal-digit Gronsfeld key.
@[export: 'gronsfeld_cipher']
pub fn gronsfeld_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 1 || length > 321 { return -1 }
    mut separator := usize(0)
    for separator < length && unsafe { input[separator] != 0 } { separator++ }
    if separator == length { return -1 }
    text_length := separator
    key_length := length - separator - 1
    if text_length > 256 || key_length > 64 { return -1 }

    for index := usize(0); index < text_length; index++ {
        value := unsafe { input[index] }
        if value < 1 || value > 127 { return -1 }
    }
    for index := usize(0); index < key_length; index++ {
        value := unsafe { input[separator + 1 + index] }
        if value < 48 || value > 57 { return -1 }
    }
    if key_length == 0 {
        for index := usize(0); index < text_length; index++ {
            value := unsafe { input[index] }
            if (value >= 65 && value <= 90) || (value >= 97 && value <= 122) { return -1 }
        }
    }
    if output_capacity < text_length { return -2 }

    for index := usize(0); index < text_length; index++ {
        value := unsafe { input[index] }
        mut mapped := value
        if value >= 65 && value <= 90 {
            shift := unsafe { input[separator + 1 + index % key_length] } - 48
            mapped = 65 + (value - 65 + shift) % 26
        } else if value >= 97 && value <= 122 {
            shift := unsafe { input[separator + 1 + index % key_length] } - 48
            mapped = 65 + (value - 97 + shift) % 26
        }
        unsafe { output[index] = u8(mapped) }
    }
    return i64(text_length)
}
