module base64

fn base64_value(byte i64) i64 {
    if byte >= i64(`A`) && byte <= i64(`Z`) { return byte - i64(`A`) }
    if byte >= i64(`a`) && byte <= i64(`z`) { return byte - i64(`a`) + 26 }
    if byte >= i64(`0`) && byte <= i64(`9`) { return byte - i64(`0`) + 52 }
    if byte == i64(`+`) { return 62 }
    if byte == i64(`/`) { return 63 }
    return -1
}

// Encode and decode bytes with the RFC 4648 Base64 alphabet.
@[export: 'base64']
pub fn base64(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 1 || length > 66 { return -1 }
    mode := unsafe { input[0] }
    if mode == 0 {
        count := length - 1
        for index := usize(1); index < length; index++ {
            byte := unsafe { input[index] }
            if byte < 0 || byte > 255 { return -1 }
        }
        mut output_length := usize(0)
        if count > 0 { output_length = ((count + 2) / 3) * 4 }
        symbols := (count * 8 + 5) / 6
        if output_capacity < output_length { return -2 }
        alphabet := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        for index := usize(0); index < output_length; index++ {
            if index >= symbols {
                unsafe { output[index] = u8(`=`) }
            } else {
                mut value := u8(0)
                for bit := index * 6; bit < index * 6 + 6; bit++ {
                    value <<= 1
                    if bit < count * 8 {
                        byte := unsafe { u8(input[1 + bit / 8]) }
                        value |= (byte >> u8(7 - bit % 8)) & 1
                    }
                }
                unsafe { output[index] = alphabet[value] }
            }
        }
        return i64(output_length)
    }
    if mode != 1 { return -1 }
    encoded_length := length - 1
    mut content_length := encoded_length
    for index := usize(0); index < encoded_length; index++ {
        if unsafe { input[index + 1] } == i64(`=`) { content_length = index; break }
    }
    padding := encoded_length - content_length
    for index := usize(0); index < content_length; index++ {
        if base64_value(unsafe { input[index + 1] }) < 0 { return -1 }
    }
    for index := content_length; index < encoded_length; index++ {
        if unsafe { input[index + 1] } != i64(`=`) { return -1 }
    }
    remainder := content_length % 4
    mut expected_padding := usize(0)
    if remainder == 2 { expected_padding = 2 }
    else if remainder == 3 { expected_padding = 1 }
    else if remainder != 0 { return -1 }
    if padding != 0 && (encoded_length % 4 != 0 || padding != expected_padding) { return -1 }
    if content_length > 0 && remainder != 0 {
        final_value := usize(base64_value(unsafe { input[content_length] }))
        unused := if remainder == 2 { usize(4) } else { usize(2) }
        if final_value % (usize(1) << unused) != 0 { return -1 }
    }
    output_length := content_length * 6 / 8
    if output_capacity < output_length { return -2 }
    for index := usize(0); index < output_length; index++ {
        mut byte := u8(0)
        for bit := index * 8; bit < index * 8 + 8; bit++ {
            symbol := usize(base64_value(unsafe { input[1 + bit / 6] }))
            byte = (byte << 1) | u8((symbol / (usize(1) << (5 - bit % 6))) % 2)
        }
        unsafe { output[index] = byte }
    }
    return i64(output_length)
}
