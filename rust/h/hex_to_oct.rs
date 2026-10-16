const INVALID_RESULT: i64 = -2_147_483_649;

fn hex_digit(code: i64) -> Option<u32> {
    match code {
        48..=57 => Some((code - 48) as u32),
        65..=70 => Some((code - 55) as u32),
        97..=102 => Some((code - 87) as u32),
        _ => None,
    }
}

fn signed_i32(bits: u32) -> i64 {
    if bits <= i32::MAX as u32 { bits as i64 } else { bits as i64 - 4_294_967_296 }
}

#[no_mangle]
pub unsafe extern "C" fn hex_to_oct(input: *const i64, length: usize) -> i64 {
    if length > 8 || (length != 0 && input.is_null()) { return INVALID_RESULT; }
    let mut decimal_bits = 0u32;
    for index in 0..length {
        let Some(digit) = hex_digit(*input.add(index)) else { return INVALID_RESULT; };
        decimal_bits = decimal_bits.wrapping_mul(16).wrapping_add(digit);
    }
    let mut decimal = signed_i32(decimal_bits);
    if decimal <= 0 { return 0; }

    let mut octal_bits = 0u32;
    let mut place_value = 1u32;
    while decimal > 0 {
        octal_bits = octal_bits.wrapping_add((decimal % 8) as u32 * place_value);
        decimal /= 8;
        place_value = place_value.wrapping_mul(10);
    }
    signed_i32(octal_bits)
}
