fn hex_nibble(value: i64) -> i64 {
    if (48..=57).contains(&value) { return value - 48; }
    if (65..=70).contains(&value) { return value - 65 + 10; }
    if (97..=102).contains(&value) { return value - 97 + 10; }
    -1
}

#[no_mangle]
pub unsafe extern "C" fn hex_to_rgb(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 6 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut packed_rgb = 0i64;
    for value in values {
        let nibble = hex_nibble(*value);
        if nibble < 0 { return -1; }
        packed_rgb = (packed_rgb << 4) | nibble;
    }
    packed_rgb
}
