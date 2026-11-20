#[no_mangle]
pub unsafe extern "C" fn shannon_fano_elias_symbol_codes(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=10).contains(&length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let raw_n = values[0];
    if !(1..=8).contains(&raw_n) || length != raw_n as usize + 1 {
        return -1;
    }
    let n = raw_n as usize;
    let mut total = 0_i64;
    for &weight in &values[1..] {
        if !(1..=15).contains(&weight) {
            return -1;
        }
        total += weight;
    }
    if total > 120 {
        return -1;
    }

    let mut staged = [0_u8; 17];
    staged[0] = n as u8;
    let mut prefix = 0_i64;
    for i in 0..n {
        let weight = values[1 + i];
        let mut bits = 1_u32;
        while (1_i64 << (bits - 1)) * weight < total {
            bits += 1;
        }
        let numerator = (2 * prefix + weight) * (1_i64 << (bits - 1));
        let code = (numerator / total) as u8;
        staged[1 + 2 * i] = bits as u8;
        staged[2 + 2 * i] = code << (8 - bits);
        prefix += weight;
    }
    let needed = 1 + 2 * n;
    if output.is_null() || capacity < needed {
        return -2;
    }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, needed) };
    needed as i64
}
