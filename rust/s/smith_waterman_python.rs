const MAX_SEQUENCE_LENGTH: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 38;
const SCORE_STRIDE: usize = 17;
const MAX_OUTPUT_BYTES: usize = 1233;

fn put_u32_le(output: &mut [u8; MAX_OUTPUT_BYTES], position: &mut usize, value: u32) {
    let mut bits = value;
    for _ in 0..4 {
        output[*position] = (bits & 0xff) as u8;
        bits >>= 8;
        *position += 1;
    }
}

fn put_i32_le(output: &mut [u8; MAX_OUTPUT_BYTES], position: &mut usize, value: i32) {
    put_u32_le(output, position, value as u32);
}

#[no_mangle]
pub unsafe extern "C" fn smith_waterman_python(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let query_length_value = values[0];
    let subject_length_value = values[1];
    let match_score = values[2];
    let mismatch_score = values[3];
    let gap_score = values[4];
    if !(0..=MAX_SEQUENCE_LENGTH as i64).contains(&query_length_value) ||
        !(0..=MAX_SEQUENCE_LENGTH as i64).contains(&subject_length_value) ||
        !(1..=5).contains(&match_score) || !(-5..=-1).contains(&mismatch_score) ||
        !(-5..=-1).contains(&gap_score) { return -1; }
    let query_length = query_length_value as usize;
    let subject_length = subject_length_value as usize;
    if input_length != 5 + query_length + subject_length { return -1; }

    let mut query = [0_u8; MAX_SEQUENCE_LENGTH];
    let mut subject = [0_u8; MAX_SEQUENCE_LENGTH];
    for (index, &value) in values[5..].iter().enumerate() {
        if !((65..=90).contains(&value) || (97..=122).contains(&value) || value == 45) { return -1; }
        let character = if (97..=122).contains(&value) { (value - 32) as u8 } else { value as u8 };
        if index < query_length { query[index] = character; }
        else { subject[index - query_length] = character; }
    }

    let mut scores = [0_i32; SCORE_STRIDE * SCORE_STRIDE];
    for row in 1..=query_length {
        for column in 1..=subject_length {
            let query_char = query[row - 1];
            let subject_char = subject[column - 1];
            let pair_score = if query_char == b'-' || subject_char == b'-' {
                gap_score
            } else if query_char == subject_char {
                match_score
            } else {
                mismatch_score
            } as i32;
            let diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1] + pair_score;
            let above = scores[(row - 1) * SCORE_STRIDE + column] + gap_score as i32;
            let left = scores[row * SCORE_STRIDE + column - 1] + gap_score as i32;
            scores[row * SCORE_STRIDE + column] = 0.max(diagonal).max(above).max(left);
        }
    }

    let mut maximum = -1_i32;
    let mut maximum_row = 0;
    let mut maximum_column = 0;
    for row in 0..=query_length {
        for column in 0..=subject_length {
            let value = scores[row * SCORE_STRIDE + column];
            if value > maximum {
                maximum = value;
                maximum_row = row;
                maximum_column = column;
            }
        }
    }

    let mut trace_query = [0_u8; 2 * MAX_SEQUENCE_LENGTH];
    let mut trace_subject = [0_u8; 2 * MAX_SEQUENCE_LENGTH];
    let mut trace_length = 0;
    let mut row = maximum_row;
    let mut column = maximum_column;
    while row > 0 && column > 0 {
        let query_char = query[row - 1];
        let subject_char = subject[column - 1];
        let pair_score = if query_char == b'-' || subject_char == b'-' {
            -2
        } else if query_char == subject_char {
            1
        } else {
            -1
        };
        let current_score = scores[row * SCORE_STRIDE + column];
        let diagonal_score = scores[(row - 1) * SCORE_STRIDE + column - 1] + pair_score;
        if current_score == diagonal_score {
            trace_query[trace_length] = query_char;
            trace_subject[trace_length] = subject_char;
            row -= 1;
            column -= 1;
        } else if current_score == scores[(row - 1) * SCORE_STRIDE + column] - 2 {
            trace_query[trace_length] = query_char;
            trace_subject[trace_length] = b'-';
            row -= 1;
        } else {
            trace_query[trace_length] = b'-';
            trace_subject[trace_length] = subject_char;
            column -= 1;
        }
        trace_length += 1;
    }

    let alignment_length = if trace_length == 0 { 0 } else { 2 * trace_length + 1 };
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut position = 0;
    put_u32_le(&mut staged, &mut position, (query_length + 1) as u32);
    put_u32_le(&mut staged, &mut position, (subject_length + 1) as u32);
    for matrix_row in 0..=query_length {
        for matrix_column in 0..=subject_length {
            put_i32_le(&mut staged, &mut position, scores[matrix_row * SCORE_STRIDE + matrix_column]);
        }
    }
    put_u32_le(&mut staged, &mut position, alignment_length as u32);
    for index in 0..trace_length {
        staged[position] = trace_query[trace_length - 1 - index];
        position += 1;
    }
    if trace_length > 0 {
        staged[position] = b'\n';
        position += 1;
    }
    for index in 0..trace_length {
        staged[position] = trace_subject[trace_length - 1 - index];
        position += 1;
    }

    if output.is_null() || output_capacity < position { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, position);
    position as i64
}
