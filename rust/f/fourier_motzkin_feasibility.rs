const MAX_VARIABLES: usize = 3;
const MAX_INEQUALITIES: usize = 6;
const MAX_ROWS: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 27;
const ROW_WIDTH: usize = 4;

#[no_mangle]
pub unsafe extern "C" fn fourier_motzkin_feasibility(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let dimension_value = values[0];
    let count_value = values[1];
    if !(1..=MAX_VARIABLES as i64).contains(&dimension_value)
        || !(1..=MAX_INEQUALITIES as i64).contains(&count_value)
    {
        return -1;
    }
    let dimension = dimension_value as usize;
    let count = count_value as usize;
    if length != 2 + count * (dimension + 1) {
        return -1;
    }

    let mut current = [0i64; MAX_ROWS * ROW_WIDTH];
    let mut next_rows = [0i64; MAX_ROWS * ROW_WIDTH];
    let mut offset = 2;
    for row in 0..count {
        for coordinate in 0..dimension {
            let value = values[offset];
            offset += 1;
            if !(-3..=3).contains(&value) {
                return -1;
            }
            current[row * ROW_WIDTH + coordinate] = value;
        }
        let bound = values[offset];
        offset += 1;
        if !(-6..=6).contains(&bound) {
            return -1;
        }
        current[row * ROW_WIDTH + 3] = bound;
    }

    let mut row_count = count;
    for variable in 0..dimension {
        let mut next_count = 0;
        for row in 0..row_count {
            if current[row * ROW_WIDTH + variable] == 0 {
                for column in 0..ROW_WIDTH {
                    next_rows[next_count * ROW_WIDTH + column] = current[row * ROW_WIDTH + column];
                }
                next_count += 1;
            }
        }
        for upper in 0..row_count {
            let positive = current[upper * ROW_WIDTH + variable];
            if positive <= 0 {
                continue;
            }
            for lower in 0..row_count {
                let negative = current[lower * ROW_WIDTH + variable];
                if negative >= 0 {
                    continue;
                }
                if next_count >= MAX_ROWS {
                    return -1;
                }
                let upper_scale = positive;
                let lower_scale = -negative;
                for coordinate in 0..dimension {
                    next_rows[next_count * ROW_WIDTH + coordinate] = if coordinate == variable {
                        0
                    } else {
                        lower_scale * current[upper * ROW_WIDTH + coordinate]
                            + upper_scale * current[lower * ROW_WIDTH + coordinate]
                    };
                }
                next_rows[next_count * ROW_WIDTH + 3] =
                    lower_scale * current[upper * ROW_WIDTH + 3]
                        + upper_scale * current[lower * ROW_WIDTH + 3];
                next_count += 1;
            }
        }
        for row in 0..next_count {
            for column in 0..ROW_WIDTH {
                current[row * ROW_WIDTH + column] = next_rows[row * ROW_WIDTH + column];
                next_rows[row * ROW_WIDTH + column] = 0;
            }
        }
        row_count = next_count;
    }
    for row in 0..row_count {
        if current[row * ROW_WIDTH + 3] < 0 {
            return 0;
        }
    }
    1
}
