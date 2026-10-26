fn put_i32(out: &mut [u8], at: usize, value: i32) { out[at..at + 4].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn prolangs_c_numeric_token(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=24).contains(&length) { return -1; }
    let mut text = [0u8; 24];
    for j in 0..length {
        let v = *input.add(j);
        if !(32..=127).contains(&v) { return -1; }
        text[j] = v as u8;
    }
    let mut i = 0usize;
    let mut integer = 0u32;
    let mut had_integer = false;
    if text[i] >= b'0' && text[i] <= b'9' {
        had_integer = true;
        while i < length && text[i] >= b'0' && text[i] <= b'9' {
            let d = (text[i] - b'0') as u32; i += 1;
            if integer > (2147483647u32 - d) / 10 { return -1; }
            integer = integer * 10 + d;
        }
        if i == length {
            if capacity < 12 || output.is_null() { return -2; }
            let out = std::slice::from_raw_parts_mut(output, capacity);
            put_i32(out, 0, 256); put_i32(out, 4, integer as i32); put_i32(out, 8, 0); return 12;
        }
    }
    let mut frac_digits = 0u32; let mut frac_count = 0; let mut leading_zeros = 0; let mut has_dot = false;
    if i < length && text[i] == b'.' {
        has_dot = true; i += 1;
        while i < length && text[i] == b'0' { leading_zeros += 1; i += 1; }
        if leading_zeros > 6 { return -1; }
        while i < length && text[i] >= b'0' && text[i] <= b'9' {
            if frac_count == 6 { return -1; }
            frac_digits = frac_digits * 10 + (text[i] - b'0') as u32; frac_count += 1; i += 1;
        }
        if leading_zeros + frac_count > 6 { return -1; }
    }
    let mut value: f32 = 0.0;
    if frac_count != 0 {
        value = frac_digits as f32;
        while value >= 1.0 { value /= 10.0; }
        while leading_zeros > 0 { value /= 10.0; leading_zeros -= 1; }
    }
    value += integer as f32;
    let mut has_exp = false;
    if i < length && (text[i] == b'e' || text[i] == b'E') {
        has_exp = true; i += 1; let mut sign = 1;
        if i < length && (text[i] == b'+' || text[i] == b'-') { if text[i] == b'-' { sign = -1; } i += 1; }
        if i == length || text[i] < b'0' || text[i] > b'9' { return -1; }
        let mut exponent = 0i32;
        while i < length && text[i] >= b'0' && text[i] <= b'9' { exponent = exponent * 10 + (text[i] - b'0') as i32; i += 1; if exponent > 6 { return -1; } }
        exponent *= sign;
        while exponent > 0 { value *= 10.0; exponent -= 1; }
        while exponent < 0 { value /= 10.0; exponent += 1; }
    }
    if i != length || (!has_dot && !has_exp) || (!had_integer && !has_dot) { return -1; }
    if capacity < 12 || output.is_null() { return -2; }
    let out = std::slice::from_raw_parts_mut(output, capacity);
    put_i32(out, 0, 2001); put_i32(out, 4, integer as i32); put_i32(out, 8, value.to_bits() as i32); 12
}
