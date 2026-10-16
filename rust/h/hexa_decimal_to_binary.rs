fn hex_digit(code: i64) -> Option<u32> {
    match code {
        48..=57 => Some((code - 48) as u32),
        65..=70 => Some((code - 55) as u32),
        97..=102 => Some((code - 87) as u32),
        _ => None,
    }
}

#[no_mangle]
pub unsafe extern "C" fn hexa_decimal_to_binary(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length == 0 || length > 65 { return -1; }
    let first_digit = if *input == 45 || *input == 43 { 1 } else { 0 };
    let negative = *input == 45;
    if first_digit == length { return -1; }
    let limit: u64 = if negative { 2_147_483_648 } else { 2_147_483_647 };
    let mut value: u64 = 0;
    for index in first_digit..length {
        let Some(digit) = hex_digit(*input.add(index)) else { return -1; };
        if value > (limit - digit as u64) / 16 { return -1; }
        value = value * 16 + digit as u64;
    }
    let bits: u32 = if negative && value != 0 { (4_294_967_296u64 - value) as u32 } else { value as u32 };
    let mut width = 0;
    let mut remaining = bits;
    while remaining != 0 {
        width += 1;
        remaining >>= 1;
    }
    if negative && value != 0 { width = 32; }
    else if width < 8 { width = 8; }
    let mut buffer = [0u8; 32];
    remaining = bits;
    for position in (0..width).rev() {
        buffer[position] = b'0' + (remaining & 1) as u8;
        remaining >>= 1;
    }
    if width > output_capacity || output.is_null() { return -2; }
    for index in 0..width { *output.add(index) = buffer[index]; }
    width as i64
}
