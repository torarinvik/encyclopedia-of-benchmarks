/// Encode and decode bytes with the RFC 4648 Base64 alphabet.
const BASE64_ALPHABET: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

fn base64_value(byte: i64) -> i64 {
    if (b'A' as i64..=b'Z' as i64).contains(&byte) { return byte - b'A' as i64; }
    if (b'a' as i64..=b'z' as i64).contains(&byte) { return byte - b'a' as i64 + 26; }
    if (b'0' as i64..=b'9' as i64).contains(&byte) { return byte - b'0' as i64 + 52; }
    if byte == b'+' as i64 { return 62; }
    if byte == b'/' as i64 { return 63; }
    -1
}

#[no_mangle]
pub unsafe extern "C" fn base64(input: *const i64, length: usize,
                                output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(1..=66).contains(&length) { return -1; }
    let mode = *input;
    if mode == 0 {
        let count = length - 1;
        for i in 1..length {
            let byte = *input.add(i);
            if !(0..=255).contains(&byte) { return -1; }
        }
        let output_length = if count == 0 { 0 } else { ((count + 2) / 3) * 4 };
        let symbols = (count * 8 + 5) / 6;
        if (output.is_null() && output_length != 0) || output_capacity < output_length { return -2; }
        for i in 0..output_length {
            if i >= symbols { *output.add(i) = b'='; continue; }
            let mut value = 0u8;
            for bit in i * 6..i * 6 + 6 {
                value <<= 1;
                if bit < count * 8 {
                    let byte = *input.add(1 + bit / 8) as u8;
                    value |= (byte >> (7 - bit % 8)) & 1;
                }
            }
            *output.add(i) = BASE64_ALPHABET[value as usize];
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
    for i in 0..content_length { if base64_value(*input.add(i + 1)) < 0 { return -1; } }
    for i in content_length..encoded_length { if *input.add(i + 1) != b'=' as i64 { return -1; } }
    let remainder = content_length % 4;
    let expected_padding = match remainder { 0 => 0, 2 => 2, 3 => 1, _ => return -1 };
    if padding != 0 && (encoded_length % 4 != 0 || padding != expected_padding) { return -1; }
    if content_length != 0 && remainder != 0 {
        let final_value = base64_value(*input.add(content_length)) as usize;
        let unused = if remainder == 2 { 4 } else { 2 };
        if final_value & ((1usize << unused) - 1) != 0 { return -1; }
    }
    let output_length = content_length * 6 / 8;
    if (output.is_null() && output_length != 0) || output_capacity < output_length { return -2; }
    for i in 0..output_length {
        let mut byte = 0u8;
        for bit in i * 8..i * 8 + 8 {
            let symbol = base64_value(*input.add(1 + bit / 6)) as usize;
            byte = (byte << 1) | (((symbol >> (5 - bit % 6)) & 1) as u8);
        }
        *output.add(i) = byte;
    }
    output_length as i64
}
