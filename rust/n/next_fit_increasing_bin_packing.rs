fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn next_fit_increasing_bin_packing(input: *const i64, length: usize,
                                                            output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 65 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n0 = values[0];
    if !(0..=64).contains(&n0) || length != 1 + n0 as usize { return -1; }
    let n = n0 as usize;
    if values[1..].iter().any(|&size| !(1..=1_000_000).contains(&size)) { return -1; }

    let mut order = [0_usize; 64];
    let mut assignments = [0_i64; 64];
    for i in 0..n { order[i] = i; }
    // Stable ascending insertion sort; original indices break ties.
    for i in 1..n {
        let item = order[i];
        let mut j = i;
        while j > 0 && values[order[j - 1] + 1] > values[item + 1] {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = item;
    }
    let (mut bins, mut remaining) = (0_i64, 0_i64);
    for rank in 0..n {
        let item = order[rank];
        let size = values[item + 1];
        if bins == 0 || size > remaining {
            assignments[item] = bins;
            bins += 1;
            remaining = 1_000_000 - size;
        } else {
            assignments[item] = bins - 1;
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
