/// Decode a reflected Gray-code bit string to a nonnegative binary integer.
#[no_mangle]
pub unsafe extern "C" fn gray_to_decimal(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=64).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let bit_length = values[0];
    if !(1..=63).contains(&bit_length) || length != bit_length as usize + 1 {
        return -1;
    }

    let mut prefix = 0i64;
    let mut binary = 0i64;
    for &character in &values[1..] {
        if character != 48 && character != 49 {
            return -1;
        }
        prefix ^= character - 48;
        binary = binary * 2 + prefix;
    }
    binary
}
