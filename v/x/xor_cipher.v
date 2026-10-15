module xor_cipher

// XOR each input byte with a repeating key byte sequence.
@[export: 'xor_cipher']
pub fn xor_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 3 || length > 66 { return -1 }
    text_size := unsafe { input[0] }
    key_size := unsafe { input[1] }
    if text_size < 0 || text_size > 63 || key_size < 1 || key_size > 63 { return -1 }
    text_length := usize(text_size)
    key_length := usize(key_size)
    if length != 2 + text_length + key_length { return -1 }
    for index := usize(0); index < text_length + key_length; index++ {
        value := unsafe { input[2 + index] }
        if value < 0 || value > 255 { return -1 }
    }
    if output_capacity < text_length { return -2 }
    for index := usize(0); index < text_length; index++ {
        text_byte := unsafe { input[2 + index] }
        key_byte := unsafe { input[2 + text_length + index % key_length] }
        unsafe { output[index] = u8(text_byte ^ key_byte) }
    }
    return i64(text_length)
}
