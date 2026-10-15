const MAX_INPUT_LENGTH: usize = 32;

#[no_mangle]
pub extern "C" fn is_ip_v4_address_valid(bytes: *const i64, length: usize) -> i64 {
    if (bytes.is_null() && length != 0) || length > MAX_INPUT_LENGTH { return -1; }
    if length == 0 { return 0; }
    let values = unsafe { std::slice::from_raw_parts(bytes, length) };
    for &value in values {
        if !(0..=127).contains(&value) { return -1; }
    }
    let mut segment_count = 0;
    let mut digit_count = 0;
    let mut octet = 0_i64;
    let mut leading_zero = false;
    for &value in values {
        if value == 46 {
            if digit_count == 0 || octet > 255 || segment_count >= 3 { return 0; }
            segment_count += 1;
            digit_count = 0;
            octet = 0;
            leading_zero = false;
        } else {
            if !(48..=57).contains(&value) { return 0; }
            if digit_count == 0 { leading_zero = value == 48; }
            else if leading_zero { return 0; }
            octet = octet * 10 + value - 48;
            if octet > 255 { return 0; }
            digit_count += 1;
            if digit_count > 3 { return 0; }
        }
    }
    i64::from(segment_count == 3 && digit_count > 0 && octet <= 255)
}
