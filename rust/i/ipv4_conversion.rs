const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub unsafe extern "C" fn ipv4_conversion(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 4 {
        return INVALID_RESULT;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let mut address = 0i64;
    for &octet in values {
        if !(0..=255).contains(&octet) {
            return INVALID_RESULT;
        }
        address = address * 256 + octet;
    }
    address
}
