fn binary32_ge(a: u32, b: u32) -> bool {
    let exp_a = (a >> 23) & 0xff; let frac_a = a & 0x7f_ffff;
    let exp_b = (b >> 23) & 0xff; let frac_b = b & 0x7f_ffff;
    if (exp_a == 0xff && frac_a != 0) || (exp_b == 0xff && frac_b != 0) { return false; }
    let mag_a = a & 0x7fff_ffff; let mag_b = b & 0x7fff_ffff;
    if mag_a == 0 && mag_b == 0 { return true; }
    let neg_a = (a >> 31) != 0; let neg_b = (b >> 31) != 0;
    if neg_a != neg_b { return !neg_a; }
    if neg_a { mag_a <= mag_b } else { mag_a >= mag_b }
}

#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_valid_index_key(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length < 1 || length > 9 || length != 8 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(raw, length) };
    let mut bits = [0_u32; 8];
    for i in 0..8 {
        if values[i] < 0 || values[i] as u64 > u32::MAX as u64 { return -1; }
        bits[i] = values[i] as u32;
    }
    for d in 0..4 { if binary32_ge(bits[d], bits[4+d]) { return 0; } }
    1
}
