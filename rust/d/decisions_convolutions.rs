const MAX_DECISIONS: i64 = 64;
const MAX_CRITERIA: i64 = 16;
const MAX_VALUE: i64 = 100_000;

#[no_mangle]
pub unsafe extern "C" fn decisions_convolutions(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let method = values[0];
    let n_arg = values[1];
    let m_arg = values[2];
    if (method != 0 && method != 1) || !(1..=MAX_DECISIONS).contains(&n_arg)
        || !(1..=MAX_CRITERIA).contains(&m_arg) { return -1; }
    let n = n_arg as usize;
    let m = m_arg as usize;
    if length != 3 + m + n * m { return -1; }
    if values[3..3 + m].iter().chain(values[3 + m..].iter()).any(|v| *v < -MAX_VALUE || *v > MAX_VALUE) { return -1; }
    let mut best_score = 0_i64;
    let mut best_index = 0_usize;
    for i in 0..n {
        let mut score = 0_i64;
        for j in 0..m {
            let product = values[3 + m + i * m + j] * values[3 + j];
            if method == 0 { score += product; }
            else if j == 0 || product < score { score = product; }
        }
        if i == 0 || score > best_score { best_score = score; best_index = i; }
    }
    best_index as i64
}
