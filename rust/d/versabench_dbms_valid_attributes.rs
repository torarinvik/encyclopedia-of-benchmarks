const MAX_ATTRIBUTES: usize = 51;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_ATTRIBUTES;

fn key_float_bits_valid(payload: i64) -> i64 {
    if payload < 0 || payload as u64 > u32::MAX as u64 { return -1; }
    let bits = payload as u32;
    let exponent = (bits >> 23) & 0xff;
    let fraction = bits & 0x7f_ffff;
    if exponent == 0xff && fraction == 0 { 0 } else { 1 }
}

#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_valid_attributes(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length < 1 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(raw, length) };
    let raw_count = values[0];
    if raw_count < 0 || raw_count > MAX_ATTRIBUTES as i64 || length != 1 + 2 * raw_count as usize { return -1; }
    for i in 0..raw_count as usize {
        let code = values[1 + 2*i]; let payload = values[2 + 2*i];
        if code < 0 || code > 50 { return 0; }
        if code < 8 {
            let valid = key_float_bits_valid(payload);
            if valid < 0 { return -1; }
            if valid == 0 { return 0; }
        } else {
            if payload != 0 && payload != 1 { return -1; }
            if payload == 0 { return 0; }
        }
    }
    1
}
