const MAX_PAYLOAD_BYTES: usize = 256;
const MAX_INPUT_LENGTH: usize = 259;
const OUTPUT_BYTES: usize = 16;

fn utf8_scalar_count(bytes: &[u8]) -> i64 {
    let mut index = 0usize;
    let mut count = 0i64;
    while index < bytes.len() {
        let lead = bytes[index];
        if (1..=0x7f).contains(&lead) {
            index += 1;
        } else if (0xc2..=0xdf).contains(&lead) {
            if index + 1 >= bytes.len() || !(0x80..=0xbf).contains(&bytes[index + 1]) { return -1; }
            index += 2;
        } else if (0xe0..=0xef).contains(&lead) {
            if index + 2 >= bytes.len() { return -1; }
            let second = bytes[index + 1];
            let third = bytes[index + 2];
            if !(0x80..=0xbf).contains(&second) || !(0x80..=0xbf).contains(&third)
                || (lead == 0xe0 && second < 0xa0) || (lead == 0xed && second > 0x9f) {
                return -1;
            }
            index += 3;
        } else {
            return -1;
        }
        count += 1;
    }
    count
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        *output.add(offset + index) = *byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn length(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, input_length);
    if input[0] < 0 || input[0] > MAX_PAYLOAD_BYTES as i64 { return -1; }
    let payload_length = input[0] as usize;
    if input_length != payload_length + 2 { return -1; }

    let mut payload = [0u8; MAX_PAYLOAD_BYTES];
    for index in 0..=payload_length {
        let value = input[index + 1];
        if !(0..=255).contains(&value) { return -1; }
        if index == payload_length {
            if value != 0 { return -1; }
        } else {
            if value == 0 { return -1; }
            payload[index] = value as u8;
        }
    }
    let scalar_count = utf8_scalar_count(&payload[..payload_length]);
    if scalar_count < 0 { return -1; }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }

    put_i64_le(output, 0, payload_length as i64);
    put_i64_le(output, 8, scalar_count);
    OUTPUT_BYTES as i64
}
