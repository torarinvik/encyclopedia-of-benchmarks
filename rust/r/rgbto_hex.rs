const RGB_CHANNEL_COUNT: usize = 3;
const RGB_HEX_OUTPUT_LENGTH: usize = 7;

fn hex_digit(value: i64) -> u8 {
    if value < 10 { (b'0' + value as u8) } else { (b'a' + (value - 10) as u8) }
}

#[no_mangle]
pub unsafe extern "C" fn rgbto_hex(input: *const i64, length: usize,
                                    output: *mut u8, capacity: usize) -> i64 {
    if length != RGB_CHANNEL_COUNT || input.is_null() { return -1; }
    for i in 0..RGB_CHANNEL_COUNT {
        let value = *input.add(i);
        if !(0..=255).contains(&value) { return -1; }
    }
    if capacity < RGB_HEX_OUTPUT_LENGTH || output.is_null() { return -2; }
    *output = b'#';
    for i in 0..RGB_CHANNEL_COUNT {
        let value = *input.add(i);
        *output.add(1 + 2 * i) = hex_digit(value >> 4);
        *output.add(2 + 2 * i) = hex_digit(value & 15);
    }
    RGB_HEX_OUTPUT_LENGTH as i64
}
