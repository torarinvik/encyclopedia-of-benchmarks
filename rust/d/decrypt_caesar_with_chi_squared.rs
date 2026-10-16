/* Select the Caesar plaintext with the smallest pinned-source chi-square score. */
const FREQUENCIES: [f64; 26] = [
    0.08497, 0.01492, 0.02202, 0.04253, 0.11162, 0.02228, 0.02015,
    0.06094, 0.07546, 0.00153, 0.01292, 0.04025, 0.02406, 0.06749,
    0.07507, 0.01929, 0.00095, 0.07587, 0.06327, 0.09356, 0.02758,
    0.00978, 0.02560, 0.00150, 0.01994, 0.00077,
];

#[no_mangle]
pub unsafe extern "C" fn decrypt_caesar_with_chi_squared(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || output.is_null() || !(1..=129).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n = values[0];
    if !(0..=128).contains(&n) || length != n as usize + 1
        || values[1..].iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }
    let n = n as usize;
    if output_capacity < n + 8 { return -2; }

    let mut best_score = 0.0f64;
    let mut best_shift = 0i64;
    let mut best = [0u8; 128];
    let mut have_best = false;
    for shift in 0..26i64 {
        let mut decoded = [0u8; 128];
        let mut counts = [0i32; 26];
        for i in 0..n {
            let mut value = values[i + 1] as u8;
            if value.is_ascii_uppercase() { value += b'a' - b'A'; }
            if value.is_ascii_lowercase() {
                value = b'a' + (value - b'a' + 26 - shift as u8) % 26;
                counts[(value - b'a') as usize] += 1;
            }
            decoded[i] = value;
        }
        let mut score = 0.0f64;
        for letter in 0..26 {
            let observed = counts[letter];
            if observed > 0 {
                let expected = FREQUENCIES[letter] * observed as f64;
                let difference = observed as f64 - expected;
                score += (difference * difference) / expected;
            }
        }
        let lex_less = have_best && score == best_score
            && decoded[..n] < best[..n];
        if !have_best || score < best_score || lex_less {
            best_score = score;
            best_shift = shift;
            best[..n].copy_from_slice(&decoded[..n]);
            have_best = true;
        }
    }
    let out = std::slice::from_raw_parts_mut(output, output_capacity);
    out[..8].copy_from_slice(&best_score.to_le_bytes());
    out[8..8 + n].copy_from_slice(&best[..n]);
    best_shift
}
