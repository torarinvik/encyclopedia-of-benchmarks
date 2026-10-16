fn continuation(byte: u8) -> bool { (0x80..=0xBF).contains(&byte) }

fn decode_utf8(bytes: &[u8], index: usize) -> Option<(u32, usize)> {
    let first = bytes[index];
    if first <= 0x7F { return Some((first as u32, 1)); }
    if (0xC2..=0xDF).contains(&first) {
        if index + 1 >= bytes.len() || !continuation(bytes[index + 1]) { return None; }
        return Some((((first & 0x1F) as u32) << 6 | (bytes[index + 1] & 0x3F) as u32, 2));
    }
    if (0xE0..=0xEF).contains(&first) {
        if index + 2 >= bytes.len() { return None; }
        let second = bytes[index + 1];
        let third = bytes[index + 2];
        if !continuation(second) || !continuation(third)
            || (first == 0xE0 && second < 0xA0) || (first == 0xED && second >= 0xA0) { return None; }
        return Some((((first & 0x0F) as u32) << 12 | ((second & 0x3F) as u32) << 6
                     | (third & 0x3F) as u32, 3));
    }
    if (0xF0..=0xF4).contains(&first) {
        if index + 3 >= bytes.len() { return None; }
        let second = bytes[index + 1];
        let third = bytes[index + 2];
        let fourth = bytes[index + 3];
        if !continuation(second) || !continuation(third) || !continuation(fourth)
            || (first == 0xF0 && second < 0x90) || (first == 0xF4 && second > 0x8F) { return None; }
        return Some((((first & 0x07) as u32) << 18 | ((second & 0x3F) as u32) << 12
                     | ((third & 0x3F) as u32) << 6 | (fourth & 0x3F) as u32, 4));
    }
    None
}

fn map_turkish(codepoint: u32) -> Option<u8> {
    match codepoint {
        0x0131 => Some(b'i'), 0x0130 => Some(b'I'),
        0x00FC => Some(b'u'), 0x00DC => Some(b'U'),
        0x00F6 => Some(b'o'), 0x00D6 => Some(b'O'),
        0x015F => Some(b's'), 0x015E => Some(b'S'),
        0x00E7 => Some(b'c'), 0x00C7 => Some(b'C'),
        0x011F => Some(b'g'), 0x011E => Some(b'G'),
        _ => None,
    }
}

#[no_mangle]
pub unsafe extern "C" fn turkish_to_latin_conversion(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    const MAX_TEXT_BYTES: usize = 1024;
    if input.is_null() || length < 1 || length > MAX_TEXT_BYTES + 1 { return -1; }
    let byte_length = *input;
    if !(0..=MAX_TEXT_BYTES as i64).contains(&byte_length)
        || length != byte_length as usize + 1 { return -1; }
    let text_length = byte_length as usize;
    let mut bytes = [0u8; MAX_TEXT_BYTES];
    for index in 0..text_length {
        let value = *input.add(index + 1);
        if !(0..=255).contains(&value) { return -1; }
        bytes[index] = value as u8;
    }

    let mut result_length = 0;
    let mut index = 0;
    while index < text_length {
        let (codepoint, width) = match decode_utf8(&bytes[..text_length], index) {
            Some(decoded) => decoded,
            None => return -1,
        };
        result_length += if map_turkish(codepoint).is_some() { 1 } else { width };
        index += width;
    }
    if result_length > output_capacity || (result_length > 0 && output.is_null()) { return -2; }

    let mut written = 0;
    index = 0;
    while index < text_length {
        let (codepoint, width) = decode_utf8(&bytes[..text_length], index).unwrap();
        if let Some(mapped) = map_turkish(codepoint) {
            *output.add(written) = mapped;
            written += 1;
        } else {
            for byte in 0..width { *output.add(written + byte) = bytes[index + byte]; }
            written += width;
        }
        index += width;
    }
    result_length as i64
}
