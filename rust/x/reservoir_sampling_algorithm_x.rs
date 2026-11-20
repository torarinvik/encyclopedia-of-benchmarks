fn falling(top: i64, count: usize) -> i64 {
    (0..count).fold(1_i64, |product, offset| product * (top - offset as i64))
}

fn gcd_i64(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a
}

#[no_mangle]
pub unsafe extern "C" fn reservoir_sampling_algorithm_x(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(3..=49).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=16).contains(&values[0]) || !(1..=8).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let k = values[1] as usize;
    if !k.is_power_of_two() || k > n || length != 2+n+2*(n-k) { return -1; }
    if values[2..2+n].iter().any(|value| !(-1_000_000..=1_000_000).contains(value)) { return -1; }
    if values[2+n..].iter().any(|draw| !(0..=4_294_967_295).contains(draw)) { return -1; }
    if output.is_null() || capacity < 8*k { return -2; }
    let stream = &values[2..2+n];
    let mut sample = [0_i64; 8];
    sample[..k].copy_from_slice(&stream[..k]);
    let mut processed = k;
    let mut attempt = 0;
    while processed < n {
        let draw = values[2+n+2*attempt];
        let slot_draw = values[2+n+2*attempt+1];
        attempt += 1;
        let mut numerator = falling(processed as i64, k);
        let mut denominator = falling(processed as i64+1, k);
        let divisor = gcd_i64(numerator, denominator);
        numerator /= divisor;
        denominator /= divisor;
        let max_skip = n-processed-1;
        let mut selected = 0;
        let mut found = false;
        for skip in 0..=max_skip {
            if numerator*4_294_967_297 <= (draw+1)*denominator { selected = skip; found = true; break; }
            if skip < max_skip {
                let top = (processed+skip+1) as i64;
                numerator *= top+1-k as i64;
                denominator *= top+1;
                let reduce_by = gcd_i64(numerator, denominator);
                numerator /= reduce_by;
                denominator /= reduce_by;
            }
        }
        if !found { break; }
        sample[(slot_draw as usize) % k] = stream[processed+selected];
        processed += selected+1;
    }
    for (index, value) in sample[..k].iter().enumerate() {
        std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(), output.add(8*index), 8);
    }
    (8*k) as i64
}
