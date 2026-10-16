const INVALID_RESULT: f64 = -1.0e300;
const MAX_STRING_LENGTH: usize = 128;
const ALPHABET_SIZE: usize = 95;

#[no_mangle]
pub unsafe extern "C" fn dice_coefficient(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let len_a_raw = input[0];
    let len_b_raw = input[1];
    if !(0..=MAX_STRING_LENGTH as i64).contains(&len_a_raw) ||
        !(0..=MAX_STRING_LENGTH as i64).contains(&len_b_raw) { return INVALID_RESULT; }
    let len_a = len_a_raw as usize;
    let len_b = len_b_raw as usize;
    if length != 2 + len_a + len_b { return INVALID_RESULT; }
    if input[2..].iter().any(|code| !(32..=126).contains(code)) { return INVALID_RESULT; }
    let equal = len_a == len_b && input[2..2+len_a] == input[2+len_a..2+len_a+len_b];
    if equal { return 1.0; }
    if len_a < 2 || len_b < 2 { return 0.0; }
    let mut present = [false; ALPHABET_SIZE * ALPHABET_SIZE];
    for i in 0..len_a-1 {
        let first = (input[2+i] - 32) as usize;
        let second = (input[2+i+1] - 32) as usize;
        present[first*ALPHABET_SIZE+second] = true;
    }
    let mut common = 0usize;
    for i in 0..len_b-1 {
        let first = (input[2+len_a+i] - 32) as usize;
        let second = (input[2+len_a+i+1] - 32) as usize;
        if present[first*ALPHABET_SIZE+second] { common += 1; }
    }
    let denominator = (len_a + len_b - 2) as f64;
    let score = (2.0 * common as f64) / denominator;
    (score * 100.0).floor() / 100.0
}
