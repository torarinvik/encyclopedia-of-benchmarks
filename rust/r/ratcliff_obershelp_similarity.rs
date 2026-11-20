const MAX_TEXT: usize = 32;

fn longest_match(input: &[i64], first_base: usize, second_base: usize,
                 a0: usize, a1: usize, b0: usize, b1: usize) -> i64 {
    let mut dp = [0_i64; MAX_TEXT + 1];
    let mut best_length = 0usize;
    let mut best_a = 0usize;
    let mut best_b = 0usize;
    for i in a0..a1 {
        let mut diagonal = 0_i64;
        for column in 1..=b1 - b0 {
            let old = dp[column];
            let j = b0 + column - 1;
            if input[first_base + i] == input[second_base + j] {
                let current = diagonal as usize + 1;
                dp[column] = current as i64;
                if current > best_length {
                    best_length = current;
                    best_a = i + 1 - current;
                    best_b = j + 1 - current;
                }
            } else { dp[column] = 0; }
            diagonal = old;
        }
    }
    (best_length * 4096 + best_a * 64 + best_b) as i64
}

fn matched_characters(input: &[i64], first_base: usize, second_base: usize,
                      a0: usize, a1: usize, b0: usize, b1: usize) -> i64 {
    if a0 >= a1 || b0 >= b1 { return 0; }
    let packed = longest_match(input, first_base, second_base, a0, a1, b0, b1) as usize;
    let block = packed / 4096;
    if block == 0 { return 0; }
    let rest = packed % 4096;
    let a = rest / 64;
    let b = rest % 64;
    block as i64
        + matched_characters(input, first_base, second_base, a0, a, b0, b)
        + matched_characters(input, first_base, second_base, a + block, a1,
                             b + block, b1)
}

#[no_mangle]
pub unsafe extern "C" fn ratcliff_obershelp_similarity(input: *const i64,
                                                         length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 67 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (first_raw, second_raw) = (values[0], values[1]);
    if !(0..=MAX_TEXT as i64).contains(&first_raw)
        || !(0..=MAX_TEXT as i64).contains(&second_raw) { return -1; }
    let first_length = first_raw as usize;
    let second_length = second_raw as usize;
    if length != 2 + first_length + second_length { return -1; }
    if values[2..].iter().any(|&byte| !(1..=127).contains(&byte)) { return -1; }
    if first_length == 0 || second_length == 0 { return 0; }
    let common = matched_characters(values, 2, 2 + first_length,
                                   0, first_length, 0, second_length);
    200 * common / (first_length + second_length) as i64
}
