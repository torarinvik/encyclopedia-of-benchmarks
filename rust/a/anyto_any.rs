const MAX_ENCODED_VALUE: i64 = 999_999_999;

#[no_mangle]
pub unsafe extern "C" fn anyto_any(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut encoded = values[0];
    let source_base = values[1];
    let destination_base = values[2];
    if encoded < 0 || encoded > MAX_ENCODED_VALUE || !(2..=10).contains(&source_base)
        || !(2..=10).contains(&destination_base) { return -1; }

    let mut decimal_value = 0i64;
    let mut source_multiplier = 1i64;
    while encoded > 0 {
        let digit = encoded % 10;
        if digit >= source_base { return -1; }
        decimal_value += digit * source_multiplier;
        source_multiplier *= source_base;
        encoded /= 10;
    }

    let mut result = 0i64;
    let mut destination_multiplier = 1i64;
    while decimal_value > 0 {
        let digit = decimal_value % destination_base;
        result += digit * destination_multiplier;
        decimal_value /= destination_base;
        if decimal_value > 0 {
            if destination_multiplier > MAX_ENCODED_VALUE / 10 { return -1; }
            destination_multiplier *= 10;
        }
    }
    result
}
