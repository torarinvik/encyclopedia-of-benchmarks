const MAX_SEQUENCE_LENGTH: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 38;
const SCORE_STRIDE: usize = 17;

#[no_mangle]
pub unsafe extern "C" fn smith_waterman_java(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let query_length_value = values[0];
    let subject_length_value = values[1];
    let match_score = values[2];
    let mismatch_score = values[3];
    let gap_score = values[4];
    if query_length_value < 0 || query_length_value > MAX_SEQUENCE_LENGTH as i64 ||
        subject_length_value < 0 || subject_length_value > MAX_SEQUENCE_LENGTH as i64 ||
        !(1..=5).contains(&match_score) || !(-5..=-1).contains(&mismatch_score) ||
        !(-5..=-1).contains(&gap_score) { return -1; }
    let query_length = query_length_value as usize;
    let subject_length = subject_length_value as usize;
    if length != 5 + query_length + subject_length { return -1; }
    for &value in &values[5..] {
        if !((b'A' as i64..=b'Z' as i64).contains(&value) ||
            (b'a' as i64..=b'z' as i64).contains(&value) || value == b'-' as i64) { return -1; }
    }

    let mut scores = [0_i64; SCORE_STRIDE * SCORE_STRIDE];
    let mut maximum = 0_i64;
    for row in 1..=query_length {
        for column in 1..=subject_length {
            let query_char = values[4 + row];
            let subject_char = values[4 + query_length + column];
            let pair_score = if query_char == subject_char { match_score } else { mismatch_score };
            let diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1] + pair_score;
            let above = scores[(row - 1) * SCORE_STRIDE + column] + gap_score;
            let left = scores[row * SCORE_STRIDE + column - 1] + gap_score;
            let value = 0.max(diagonal).max(above).max(left);
            scores[row * SCORE_STRIDE + column] = value;
            maximum = maximum.max(value);
        }
    }
    maximum
}
