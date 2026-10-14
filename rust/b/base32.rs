/// Encode and decode bytes with the RFC 4648 Base32 alphabet.
fn base32_value(byte: i64) -> i64 {
    if (b'A' as i64..=b'Z' as i64).contains(&byte) { return byte - b'A' as i64; }
    if (b'2' as i64..=b'7' as i64).contains(&byte) { return byte - b'2' as i64 + 26; }
    -1
}

#[no_mangle]
pub unsafe extern "C" fn base32(input: *const i64, length: usize,
                                output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(1..=66).contains(&length) { return -1; }
    let mode = *input;
    if mode == 0 {
        let count = length - 1;
        for i in 1..length {
            let byte = *input.add(i);
            if !(0..=255).contains(&byte) { return -1; }
        }
        let output_length = if count == 0 { 0 } else { ((count + 4) / 5) * 8 };
        if (output.is_null() && output_length != 0) || output_capacity < output_length { return -2; }
        let mut written = 0;
        let mut start = 0;
        while start < count {
            let bytes = (count - start).min(5);
            let bits = bytes * 8;
            let symbols = (bits + 4) / 5;
            for symbol in 0..8 {
                if symbol >= symbols {
                    *output.add(written) = b'=';
                } else {
                    let mut value = 0u8;
                    for bit in symbol * 5..symbol * 5 + 5 {
                        value <<= 1;
                        if bit < bits {
                            let byte = *input.add(1 + start + bit / 8) as u8;
                            value |= (byte >> (7 - bit % 8)) & 1;
                        }
                    }
                    *output.add(written) = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"[value as usize];
                }
                written += 1;
            }
            start += 5;
        }
        return output_length as i64;
    }
    if mode != 1 { return -1; }
    let encoded_length = length - 1;
    let mut content_length = encoded_length;
    for i in 0..encoded_length {
        if *input.add(i + 1) == b'=' as i64 { content_length = i; break; }
    }
    let padding = encoded_length - content_length;
    for i in 0..content_length { if base32_value(*input.add(i + 1)) < 0 { return -1; } }
    for i in content_length..encoded_length { if *input.add(i + 1) != b'=' as i64 { return -1; } }
    let remainder = content_length % 8;
    let expected_padding = match remainder { 0 => 0, 2 => 6, 4 => 4, 5 => 3, 7 => 1, _ => return -1 };
    if padding != 0 && (encoded_length % 8 != 0 || padding != expected_padding) { return -1; }
    if content_length != 0 && remainder != 0 {
        let final_value = base32_value(*input.add(content_length)) as usize;
        let unused = match remainder { 2 => 2, 4 => 4, 5 => 1, _ => 3 };
        if final_value & ((1usize << unused) - 1) != 0 { return -1; }
    }
    let output_length = content_length * 5 / 8;
    if (output.is_null() && output_length != 0) || output_capacity < output_length { return -2; }
    for i in 0..output_length {
        let mut byte = 0u8;
        for bit in i * 8..i * 8 + 8 {
            let symbol = base32_value(*input.add(1 + bit / 5)) as usize;
            byte = (byte << 1) | (((symbol >> (4 - bit % 5)) & 1) as u8);
        }
        *output.add(i) = byte;
    }
    output_length as i64
}
