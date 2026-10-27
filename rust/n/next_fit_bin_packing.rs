fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn next_fit_bin_packing(input: *const i64, length: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 65 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n0 = values[0];
    if !(0..=64).contains(&n0) || length != 1 + n0 as usize { return -1; }
    let n = n0 as usize;
    if values[1..].iter().any(|&size| !(1..=1_000_000).contains(&size)) { return -1; }
    let mut assignments = [0i64; 64];
    let mut bins = 0i64;
    let mut remaining = 0i64;
    for i in 0..n {
        let size = values[i + 1];
        if bins == 0 || size > remaining {
            assignments[i] = bins;
            bins += 1;
            remaining = 1_000_000 - size;
        } else {
            assignments[i] = bins - 1;
            remaining -= size;
        }
    }
    let bytes = 8 * (n + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    put_i64(dst, 0, bins);
    for i in 0..n { put_i64(dst, i + 1, assignments[i]); }
    bytes as i64
}
