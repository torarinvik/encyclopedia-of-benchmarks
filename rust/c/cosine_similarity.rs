const MAX_STRING_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 132;
const ALPHABET_SIZE: usize = 95;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn cosine_similarity(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let left_length_value = unsafe { *input };
    let right_length_value = unsafe { *input.add(1) };
    if left_length_value < 0 || left_length_value > MAX_STRING_LENGTH as i64
            || right_length_value < 0 || right_length_value > MAX_STRING_LENGTH as i64 {
        return INVALID_RESULT;
    }
    let left_length = left_length_value as usize;
    let right_length = right_length_value as usize;
    if length != 2 + left_length + right_length { return INVALID_RESULT; }

    let mut left_counts = [0u64; ALPHABET_SIZE];
    let mut right_counts = [0u64; ALPHABET_SIZE];
    for i in 0..left_length {
        let mut value = unsafe { *input.add(2 + i) };
        if !(32..=126).contains(&value) { return INVALID_RESULT; }
        if (65..=90).contains(&value) { value += 32; }
        left_counts[(value - 32) as usize] += 1;
    }
    for i in 0..right_length {
        let mut value = unsafe { *input.add(2 + left_length + i) };
        if !(32..=126).contains(&value) { return INVALID_RESULT; }
        if (65..=90).contains(&value) { value += 32; }
        right_counts[(value - 32) as usize] += 1;
    }

    let mut dot_product = 0.0;
    let mut left_magnitude_squared = 0.0;
    let mut right_magnitude_squared = 0.0;
    for i in 0..ALPHABET_SIZE {
        let left = left_counts[i] as f64;
        let right = right_counts[i] as f64;
        dot_product += left * right;
        left_magnitude_squared += left * left;
        right_magnitude_squared += right * right;
    }
    if left_magnitude_squared <= 0.0 || right_magnitude_squared <= 0.0 { return 0.0; }
    dot_product / (left_magnitude_squared.sqrt() * right_magnitude_squared.sqrt())
}
