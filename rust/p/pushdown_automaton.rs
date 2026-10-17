/// Recognize the bounded language (1|2)^n 0^n with a pushdown-style counter.
#[no_mangle]
pub extern "C" fn pushdown_automaton(values: *const i64, length: usize) -> i64 {
    const MAX_BYTE_LENGTH: i64 = 256;
    const MAX_INPUT_LENGTH: usize = 257;
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let byte_length = unsafe { *values };
    if !(0..=MAX_BYTE_LENGTH).contains(&byte_length) {
        return -1;
    }
    let count = byte_length as usize;
    if length != count + 1 {
        return -1;
    }

    let payload = unsafe { std::slice::from_raw_parts(values.add(1), count) };
    if payload.iter().any(|&byte| !(48..=50).contains(&byte)) {
        return -1;
    }
    if count == 0 || count % 2 != 0 {
        return 0;
    }

    let half = count / 2;
    if payload[..half].iter().any(|&byte| byte != 49 && byte != 50) {
        return 0;
    }
    if payload[half..].iter().any(|&byte| byte != 48) {
        return 0;
    }
    1
}
