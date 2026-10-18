const MAX_SEQUENCE_LENGTH: usize = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 38;
const SCORE_STRIDE: usize = 17;
const MAX_OUTPUT_BYTES: usize = 1233;

fn pair_score(left: u8, right: u8, match_score: i32, mismatch_score: i32, gap_score: i32) -> i32 {
    if left == b'-' || right == b'-' {
        gap_score
    } else if left == right {
        match_score
    } else {
        mismatch_score
    }
}

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
pub unsafe extern "C" fn smith_waterman_rust(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    let query_length_value = values[0];
    let subject_length_value = values[1];
    let match_value = values[2];
    let mismatch_value = values[3];
    let gap_value = values[4];
    if !(0..=MAX_SEQUENCE_LENGTH as i64).contains(&query_length_value)
        || !(0..=MAX_SEQUENCE_LENGTH as i64).contains(&subject_length_value)
        || !(1..=5).contains(&match_value)
        || !(-5..=-1).contains(&mismatch_value)
        || !(-5..=-1).contains(&gap_value)
    {
        return -1;
    }
    let query_length = query_length_value as usize;
    let subject_length = subject_length_value as usize;
    if input_length != 5 + query_length + subject_length {
        return -1;
    }

    let mut query = [0_u8; MAX_SEQUENCE_LENGTH];
    let mut subject = [0_u8; MAX_SEQUENCE_LENGTH];
    for (index, &value) in values[5..].iter().enumerate() {
        if !((65..=90).contains(&value) || (97..=122).contains(&value) || value == 45) {
            return -1;
        }
        let character = if (97..=122).contains(&value) {
            (value - 32) as u8
        } else {
            value as u8
        };
        if index < query_length {
            query[index] = character;
        } else {
            subject[index - query_length] = character;
        }
    }

    let match_score = match_value as i32;
    let mismatch_score = mismatch_value as i32;
    let gap_score = gap_value as i32;
    let rows = query_length + 1;
    let columns = subject_length + 1;
    let mut scores = [0_i32; SCORE_STRIDE * SCORE_STRIDE];
    let mut maximum = 0_i32;
    let mut max_row = 0;
    let mut max_column = 0;
    for row in 1..rows {
        for column in 1..columns {
            let diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1]
                + pair_score(
                    query[row - 1],
                    subject[column - 1],
                    match_score,
                    mismatch_score,
                    gap_score,
                );
            let above = scores[(row - 1) * SCORE_STRIDE + column] + gap_score;
            let left = scores[row * SCORE_STRIDE + column - 1] + gap_score;
            let value = 0.max(diagonal).max(above).max(left);
            scores[row * SCORE_STRIDE + column] = value;
            if value > maximum {
                maximum = value;
                max_row = row;
                max_column = column;
            }
        }
    }

    let mut reverse_query = [0_u8; 2 * MAX_SEQUENCE_LENGTH];
    let mut reverse_subject = [0_u8; 2 * MAX_SEQUENCE_LENGTH];
    let mut trace_steps = 0;
    let mut row = max_row;
    let mut column = max_column;
    while row > 0 && column > 0 && scores[row * SCORE_STRIDE + column] > 0 {
        let current = scores[row * SCORE_STRIDE + column];
        let diagonal = scores[(row - 1) * SCORE_STRIDE + column - 1]
            + pair_score(
                query[row - 1],
                subject[column - 1],
                match_score,
                mismatch_score,
                gap_score,
            );
        if current == diagonal {
            reverse_query[trace_steps] = query[row - 1];
            reverse_subject[trace_steps] = subject[column - 1];
            row -= 1;
            column -= 1;
        } else if current == scores[(row - 1) * SCORE_STRIDE + column] + gap_score {
            reverse_query[trace_steps] = query[row - 1];
            reverse_subject[trace_steps] = b'-';
            row -= 1;
        } else {
            reverse_query[trace_steps] = b'-';
            reverse_subject[trace_steps] = subject[column - 1];
            column -= 1;
        }
        trace_steps += 1;
    }

    let alignment_length = if trace_steps == 0 { 0 } else { 2 * trace_steps + 1 };
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut position = 0;
    put_u32_le(&mut staged, &mut position, rows as u32);
    put_u32_le(&mut staged, &mut position, columns as u32);
    for matrix_row in 0..rows {
        for matrix_column in 0..columns {
            put_i32_le(
                &mut staged,
                &mut position,
                scores[matrix_row * SCORE_STRIDE + matrix_column],
            );
        }
    }
    put_u32_le(&mut staged, &mut position, alignment_length as u32);
    for index in 0..trace_steps {
        staged[position] = reverse_query[trace_steps - 1 - index];
        position += 1;
    }
    if trace_steps > 0 {
        staged[position] = b'\n';
        position += 1;
    }
    for index in 0..trace_steps {
        staged[position] = reverse_subject[trace_steps - 1 - index];
        position += 1;
    }

    if output.is_null() || output_capacity < position {
        return -2;
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, position);
    position as i64
}
