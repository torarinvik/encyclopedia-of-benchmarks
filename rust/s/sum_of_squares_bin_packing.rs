fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn sum_of_squares_bin_packing(input: *const i64, length: usize,
                                                       output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 66 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (capacity0, n0) = (values[0], values[1]);
    if !(1..=64).contains(&capacity0) || !(0..=64).contains(&n0) || length != 2 + n0 as usize { return -1; }
    let n = n0 as usize;
    if values[2..].iter().any(|&size| size < 1 || size > capacity0) { return -1; }
    let mut histogram = [0i64; 65];
    let mut loads = [0i64; 64];
    let mut assignments = [0i64; 64];
    let mut bins = 0usize;
    let mut score = 0i64;
    for item in 0..n {
        let size = values[item + 2];
        let mut selected = bins;
        let mut best_score = i64::MAX;
        for bin in 0..bins {
            let from = loads[bin]; let to = from + size;
            if to > capacity0 { continue; }
            let mut candidate = score;
            if from < capacity0 { candidate += (histogram[from as usize] - 1).pow(2) - histogram[from as usize].pow(2); }
            if to < capacity0 { candidate += (histogram[to as usize] + 1).pow(2) - histogram[to as usize].pow(2); }
            if candidate < best_score { best_score = candidate; selected = bin; }
        }
        let mut new_score = score;
        if size < capacity0 { new_score += (histogram[size as usize] + 1).pow(2) - histogram[size as usize].pow(2); }
        if new_score < best_score { best_score = new_score; selected = bins; }
        if selected == bins {
            loads[bins] = size; assignments[item] = bins as i64;
            if size < capacity0 { histogram[size as usize] += 1; }
            bins += 1;
        } else {
            let from = loads[selected]; let to = from + size;
            if from < capacity0 { histogram[from as usize] -= 1; }
            if to < capacity0 { histogram[to as usize] += 1; }
            loads[selected] = to; assignments[item] = selected as i64;
        }
        score = best_score;
    }
    let bytes = 8 * (n + 1);
    if output.is_null() || output_capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    put_i64(dst, 0, bins as i64);
    for i in 0..n { put_i64(dst, i + 1, assignments[i]); }
    bytes as i64
}
