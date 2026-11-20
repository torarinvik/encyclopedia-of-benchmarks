const MAX_LENGTH: usize = 8;
const MAX_PARSEABLE_LENGTH: usize = 10;
const ALPHABET_SIZE: usize = 26;

fn factorial(value: i64) -> i64 {
    let mut result = 1_i64;
    for factor in 2..=value { result *= factor; }
    result
}

fn solve(input: &[i64]) -> i64 {
    if input.is_empty() || input.len() > MAX_PARSEABLE_LENGTH { return -1; }
    let n_raw = input[0];
    if n_raw < 0 || n_raw > MAX_LENGTH as i64 { return -1; }
    let n = n_raw as usize;
    if input.len() != n + 1 || input[1..].iter().any(|&symbol| !(0..=25).contains(&symbol)) {
        return -1;
    }
    let mut frequency = [0_i64; ALPHABET_SIZE];
    for &symbol in &input[1..] { frequency[symbol as usize] += 1; }
    let denominator: i64 = frequency.iter().map(|&count| factorial(count)).product();
    let mut ways = factorial(n_raw) / denominator;
    let mut rank = 1_i64;
    let mut remaining = n_raw;
    for &actual_raw in &input[1..] {
        let actual = actual_raw as usize;
        for smaller in 0..actual {
            if frequency[smaller] > 0 {
                rank += ways * frequency[smaller] / remaining;
            }
        }
        ways = ways * frequency[actual] / remaining;
        frequency[actual] -= 1;
        remaining -= 1;
    }
    rank
}

#[no_mangle]
pub unsafe extern "C" fn alphabetic_anagrams(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
