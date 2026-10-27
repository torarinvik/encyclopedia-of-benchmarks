fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn bounded_space_best_fit_bin_packing(input: *const i64, length: usize,
                                                               output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 65 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n0 = values[0];
    if !(0..=64).contains(&n0) || length != 1 + n0 as usize { return -1; }
    let n = n0 as usize;
    if values[1..].iter().any(|&size| !(1..=1_000_000).contains(&size)) { return -1; }
    let mut loads = [0i64; 64];
    let mut assignments = [0i64; 64];
    let mut open = [false; 64];
    let mut bins = 0usize;
    for item in 0..n {
        let size = values[item + 1];
        let mut selected = bins;
        let mut least_remaining = 1_000_001i64;
        for bin in 0..bins {
            if open[bin] && loads[bin] + size <= 1_000_000 {
                let remaining = 1_000_000 - loads[bin] - size;
                if remaining < least_remaining { least_remaining = remaining; selected = bin; }
            }
        }
        if selected == bins {
            loads[bins] = size; open[bins] = size < 1_000_000;
            assignments[item] = bins as i64; bins += 1;
        } else {
            loads[selected] += size; assignments[item] = selected as i64;
            if loads[selected] == 1_000_000 { open[selected] = false; }
        }
        let mut partial_open = open[..bins].iter().filter(|&&active| active).count();
        while partial_open > 2 {
            let mut weakest = bins;
            for bin in 0..bins {
                if open[bin] && (weakest == bins || loads[bin] < loads[weakest]
                    || (loads[bin] == loads[weakest] && bin > weakest)) { weakest = bin; }
            }
            open[weakest] = false; partial_open -= 1;
        }
    }
    let bytes = 8 * (n + 1);
    if output.is_null() || output_capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    put_i64(dst, 0, bins as i64);
    for item in 0..n { put_i64(dst, item + 1, assignments[item]); }
    bytes as i64
}
