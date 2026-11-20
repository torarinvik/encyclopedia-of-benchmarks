const MIN_WORDS: usize = 7;
const MAX_WORDS: usize = 17;
const OUTPUT_BYTES: usize = 16;

fn gcd_positive(mut a: i64, mut b: i64) -> i64 {
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    a
}

fn store_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn weniger_pochhammer_partial_sum_transform(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(MIN_WORDS..=MAX_WORDS).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let n0 = values[0];
    let k0 = values[1];
    if !(0..=8).contains(&n0) || !(3..=4).contains(&k0) { return -1; }
    let n = n0 as usize;
    let k = k0 as usize;
    if input_length != n + k + 4 { return -1; }
    let term_count = n + k + 2;
    if values[2..2 + term_count].iter().any(|&x| x == 0 || !(-3..=3).contains(&x)) { return -1; }

    let mut product = 1_i64;
    for r in 0..=k { product *= values[n + r + 3]; }
    let (mut numerator, mut denominator) = (0_i64, 0_i64);
    for j in 0..=k {
        let mut choose = 1_i64;
        for r in 1..=j { choose = choose * (k - r + 1) as i64 / r as i64; }
        let mut rising = 1_i64;
        for offset in 0..k - 1 { rising *= (n + j + 1 + offset) as i64; }
        let term = values[n + j + 3];
        let mut weight = choose * rising * (product / term);
        if j & 1 != 0 { weight = -weight; }
        let mut partial = 0_i64;
        for index in 0..=n + j { partial += values[index + 2]; }
        numerator += weight * partial;
        denominator += weight;
    }
    if denominator == 0 { return -1; }
    if denominator < 0 { numerator = -numerator; denominator = -denominator; }
    let divisor = gcd_positive(numerator.abs(), denominator);
    numerator /= divisor;
    denominator /= divisor;
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }
    let destination = unsafe { std::slice::from_raw_parts_mut(output, OUTPUT_BYTES) };
    store_i64(destination, 0, numerator);
    store_i64(destination, 8, denominator);
    OUTPUT_BYTES as i64
}
