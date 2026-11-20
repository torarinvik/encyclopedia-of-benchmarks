const MODULUS: i64 = 998_244_353;
const MAX_STATES: usize = 7;

fn pow_mod(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn find_state(codes: &[i64; MAX_STATES], lengths: &[usize; MAX_STATES],
              count: usize, code: i64, length: usize) -> Option<usize> {
    (0..count).find(|&i| codes[i] == code && lengths[i] == length)
}

fn solve(word_length: usize, first: i64, second: i64) -> i64 {
    let mut codes = [0_i64; MAX_STATES];
    let mut lengths = [0_usize; MAX_STATES];
    let mut state_count = 1_usize;
    for prefix_length in 1..word_length {
        for pattern in [first, second] {
            let code = pattern >> (word_length - prefix_length);
            if find_state(&codes, &lengths, state_count, code, prefix_length).is_none() {
                codes[state_count] = code;
                lengths[state_count] = prefix_length;
                state_count += 1;
            }
        }
    }

    let mut matrix = [[0_i64; MAX_STATES + 1]; MAX_STATES];
    for row in 0..state_count {
        for column in 0..state_count {
            matrix[row][column] = if row == column { 2 } else { 0 };
        }
        for bit in 0..=1_i64 {
            let candidate = (codes[row] << 1) | bit;
            let candidate_length = lengths[row] + 1;
            if candidate_length == word_length && candidate == first {
                matrix[row][state_count] += 1;
                continue;
            }
            if candidate_length == word_length && candidate == second { continue; }
            let mut suffix_length = candidate_length.min(word_length - 1);
            let mut destination = None;
            loop {
                let suffix_mask = (1_i64 << suffix_length) - 1;
                destination = find_state(&codes, &lengths, state_count,
                                         candidate & suffix_mask, suffix_length);
                if destination.is_some() || suffix_length == 0 { break; }
                suffix_length -= 1;
            }
            let destination = destination.unwrap_or(0);
            matrix[row][destination] = (matrix[row][destination] - 1 + MODULUS) % MODULUS;
        }
    }

    for column in 0..state_count {
        let Some(pivot) = (column..state_count).find(|&row| matrix[row][column] != 0) else {
            return -1;
        };
        matrix.swap(column, pivot);
        let inverse = pow_mod(matrix[column][column], MODULUS - 2);
        for j in column..=state_count {
            matrix[column][j] = matrix[column][j] * inverse % MODULUS;
        }
        for row in 0..state_count {
            if row == column { continue; }
            let factor = matrix[row][column];
            for j in column..=state_count {
                let product = factor * matrix[column][j] % MODULUS;
                matrix[row][j] = (matrix[row][j] - product + MODULUS) % MODULUS;
            }
        }
    }
    matrix[0][state_count]
}

#[no_mangle]
pub unsafe extern "C" fn penney_game_pattern_probability(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let word_length = values[0];
    if !(1..=4).contains(&word_length) { return -1; }
    let limit = 1_i64 << word_length;
    let (first, second) = (values[1], values[2]);
    if first < 0 || second < 0 || first >= limit || second >= limit || first == second { return -1; }
    solve(word_length as usize, first, second)
}
