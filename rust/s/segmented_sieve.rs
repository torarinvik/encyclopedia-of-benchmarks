fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn segmented_sieve(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n_value = *input;
    if !(2..=10_000).contains(&n_value) { return -1; }
    let n = n_value as usize;
    let mut end = 0usize;
    while (end + 1) * (end + 1) <= n { end += 1; }
    let mut base_marks = [false; 101];
    let mut base = [0i64; 25];
    let mut base_count = 0usize;
    for i in 2..=end { base_marks[i] = true; }
    for p in 2..=end {
        if !base_marks[p] { continue; }
        base[base_count] = p as i64;
        base_count += 1;
        let mut multiple = p * p;
        while multiple <= end { base_marks[multiple] = false; multiple += p; }
    }
    let mut primes = [0i64; 1229];
    let mut prime_count = 0usize;
    for i in 0..base_count { primes[prime_count] = base[i]; prime_count += 1; }
    let mut low = end + 1;
    let mut high = (2 * end).min(n);
    while low <= n {
        let mut segment = [false; 201];
        let segment_length = high - low + 1;
        for i in 0..segment_length { segment[i] = true; }
        for i in 0..base_count {
            let p = base[i] as usize;
            let mut first = (low / p) * p;
            if first < low { first += p; }
            while first <= high { segment[first - low] = false; first += p; }
        }
        for i in 0..segment_length {
            if segment[i] { primes[prime_count] = (low + i) as i64; prime_count += 1; }
        }
        low = high + 1;
        high = (high + end).min(n);
    }
    let output_length = prime_count * 8;
    if capacity < output_length || (output_length > 0 && output.is_null()) { return -2; }
    let out = std::slice::from_raw_parts_mut(output, output_length);
    for i in 0..prime_count { put_i64_le(out, i * 8, primes[i]); }
    output_length as i64
}
