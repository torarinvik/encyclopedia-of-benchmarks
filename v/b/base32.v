module base32

fn base32_value(byte i64) i64 {
    if byte >= i64(`A`) && byte <= i64(`Z`) { return byte - i64(`A`) }
    if byte >= i64(`2`) && byte <= i64(`7`) { return byte - i64(`2`) + 26 }
    return -1
}

// Encode and decode bytes with the RFC 4648 Base32 alphabet.
@[export: 'base32']
pub fn base32(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 1 || length > 66 { return -1 }
    mode := unsafe { input[0] }
    if mode == 0 {
        count := length - 1
        for index := usize(1); index < length; index++ {
            byte := unsafe { input[index] }
            if byte < 0 || byte > 255 { return -1 }
        }
        mut output_length := usize(0)
        if count > 0 { output_length = ((count + 4) / 5) * 8 }
        if output_capacity < output_length { return -2 }
        mut written := usize(0)
        mut start := usize(0)
        for start < count {
            bytes := if count - start < 5 { count - start } else { usize(5) }
            bits := bytes * 8
            symbols := (bits + 4) / 5
            for symbol := usize(0); symbol < 8; symbol++ {
                if symbol >= symbols {
                    unsafe { output[written] = u8(`=`) }
                } else {
                    mut value := u8(0)
                    for bit := symbol * 5; bit < symbol * 5 + 5; bit++ {
                        value <<= 1
                        if bit < bits {
                            byte := unsafe { u8(input[1 + start + bit / 8]) }
                            value |= (byte >> u8(7 - bit % 8)) & 1
                        }
                    }
                    unsafe { output[written] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'[value] }
                }
                written++
            }
            start += 5
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
        if base32_value(unsafe { input[index + 1] }) < 0 { return -1 }
    }
    for index := content_length; index < encoded_length; index++ {
        if unsafe { input[index + 1] } != i64(`=`) { return -1 }
    }
    remainder := content_length % 8
    mut expected_padding := usize(0)
    if remainder == 2 { expected_padding = 6 }
    else if remainder == 4 { expected_padding = 4 }
    else if remainder == 5 { expected_padding = 3 }
    else if remainder == 7 { expected_padding = 1 }
    else if remainder != 0 { return -1 }
    if padding != 0 && (encoded_length % 8 != 0 || padding != expected_padding) { return -1 }
    if content_length > 0 && remainder != 0 {
        final_value := usize(base32_value(unsafe { input[content_length] }))
        mut unused := usize(3)
        if remainder == 2 { unused = 2 }
        else if remainder == 4 { unused = 4 }
        else if remainder == 5 { unused = 1 }
        else if remainder == 7 { unused = 3 }
        if final_value % (usize(1) << unused) != 0 { return -1 }
    }
    output_length := content_length * 5 / 8
    if output_capacity < output_length { return -2 }
    for index := usize(0); index < output_length; index++ {
        mut byte := u8(0)
        for bit := index * 8; bit < index * 8 + 8; bit++ {
            symbol := usize(base32_value(unsafe { input[1 + bit / 5] }))
            byte = (byte << 1) | u8((symbol / (usize(1) << (4 - bit % 5))) % 2)
        }
        unsafe { output[index] = byte }
    }
    return i64(output_length)
}
