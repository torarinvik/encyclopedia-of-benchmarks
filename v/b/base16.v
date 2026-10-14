module base16

fn nibble(byte i64) i64 {
    if byte >= i64(`0`) && byte <= i64(`9`) { return byte - i64(`0`) }
    if byte >= i64(`A`) && byte <= i64(`F`) { return byte - i64(`A`) + 10 }
    return -1
}

// Encode bytes as uppercase Base16 or decode uppercase Base16 bytes.
@[export: 'base16']
pub fn base16(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 1 || length > 65 { return -1 }
    mode := unsafe { input[0] }
    if mode == 0 {
        count := length - 1
        output_length := count * 2
        for index := usize(1); index < length; index++ {
            byte := unsafe { input[index] }
            if byte < 0 || byte > 255 { return -1 }
        }
        if output_capacity < output_length { return -2 }
        for index := usize(0); index < count; index++ {
            byte := unsafe { input[index + 1] }
            high := byte / 16
            low := byte % 16
            if high < 10 { unsafe { output[2 * index] = u8(`0`) + u8(high) } }
            else { unsafe { output[2 * index] = u8(`A`) + u8(high - 10) } }
            if low < 10 { unsafe { output[2 * index + 1] = u8(`0`) + u8(low) } }
            else { unsafe { output[2 * index + 1] = u8(`A`) + u8(low - 10) } }
        }
        return i64(output_length)
    }
    if mode != 1 { return -1 }
    encoded_length := length - 1
    if encoded_length % 2 != 0 { return -1 }
    for index := usize(1); index < length; index++ {
        if nibble(unsafe { input[index] }) < 0 { return -1 }
    }
    output_length := encoded_length / 2
    if output_capacity < output_length { return -2 }
    for index := usize(0); index < output_length; index++ {
        high := nibble(unsafe { input[1 + 2 * index] })
        low := nibble(unsafe { input[2 + 2 * index] })
        unsafe { output[index] = u8(high * 16 + low) }
    }
    return i64(output_length)
}
