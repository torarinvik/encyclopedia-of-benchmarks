const MAX_GROUP_COUNT: usize = 4;
const MAX_ROWS: usize = 4;
const MAX_COLUMNS: usize = 4;
const MAX_MATRIX_ELEMENTS: usize = 16;
const MAX_GROUP_MATRIX_ELEMENTS: usize = 32;
const MAX_CALL_COUNT: usize = 8;
const MAX_VALID_INPUT_LENGTH: usize = 271;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 272;

#[inline(never)]
fn rounded_multiply(left: f64, right: f64) -> f64 { left * right }

#[inline(never)]
fn rounded_add(left: f64, right: f64) -> f64 { left + right }

#[inline(never)]
fn rounded_subtract(left: f64, right: f64) -> f64 { left - right }

fn exact_bounded_integer(value: f64, minimum: usize, maximum: usize) -> Option<usize> {
    if !value.is_finite() || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    let converted = value as usize;
    if value != converted as f64 { return None; }
    Some(converted)
}

fn orthogonalize(gradient: &[f64], rows: usize, columns: usize,
                 ns_steps: usize) -> [f64; MAX_MATRIX_ELEMENTS] {
    let transposed = rows < columns;
    let working_rows = if transposed { columns } else { rows };
    let working_columns = if transposed { rows } else { columns };
    let mut matrix = [[0.0_f64; MAX_COLUMNS]; MAX_ROWS];

    for row in 0..rows {
        for column in 0..columns {
            if transposed { matrix[column][row] = gradient[row * columns + column]; }
            else { matrix[row][column] = gradient[row * columns + column]; }
        }
    }

    for _ in 0..ns_steps {
        let mut gram = [[0.0_f64; MAX_COLUMNS]; MAX_COLUMNS];
        let mut product = [[0.0_f64; MAX_COLUMNS]; MAX_ROWS];
        for left in 0..working_columns {
            for right in 0..working_columns {
                let mut sum = 0.0;
                for row in 0..working_rows {
                    sum = rounded_add(sum, rounded_multiply(matrix[row][left], matrix[row][right]));
                }
                gram[left][right] = sum;
            }
        }
        for row in 0..working_rows {
            for column in 0..working_columns {
                let mut sum = 0.0;
                for inner in 0..working_columns {
                    sum = rounded_add(sum, rounded_multiply(matrix[row][inner], gram[inner][column]));
                }
                product[row][column] = sum;
            }
        }
        for row in 0..working_rows {
            for column in 0..working_columns {
                matrix[row][column] = rounded_subtract(
                    rounded_multiply(1.5, matrix[row][column]),
                    rounded_multiply(0.5, product[row][column]),
                );
            }
        }
    }

    let mut result = [0.0_f64; MAX_MATRIX_ELEMENTS];
    for row in 0..rows {
        for column in 0..columns {
            result[row * columns + column] = if transposed {
                matrix[column][row]
            } else {
                matrix[row][column]
            };
        }
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn muon_optimizer(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 10 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) { return -1; }

    let group_count = match exact_bounded_integer(values[0], 1, MAX_GROUP_COUNT) {
        Some(value) => value, None => return -1,
    };
    let rows = match exact_bounded_integer(values[1], 1, MAX_ROWS) {
        Some(value) => value, None => return -1,
    };
    let columns = match exact_bounded_integer(values[2], 1, MAX_COLUMNS) {
        Some(value) => value, None => return -1,
    };
    let call_count = match exact_bounded_integer(values[3], 1, MAX_CALL_COUNT) {
        Some(value) => value, None => return -1,
    };
    let ns_steps = match exact_bounded_integer(values[4], 0, 5) {
        Some(value) => value, None => return -1,
    };

    let matrix_elements = rows * columns;
    if matrix_elements > MAX_MATRIX_ELEMENTS ||
       group_count * matrix_elements > MAX_GROUP_MATRIX_ELEMENTS ||
       call_count < group_count {
        return -1;
    }
    let expected_length = 7 + call_count * (1 + 2 * matrix_elements);
    if input_length != expected_length || input_length > MAX_VALID_INPUT_LENGTH { return -1; }

    let learning_rate = values[5];
    let momentum = values[6];
    if !(0.0..=0.25).contains(&learning_rate) || !(0.0..=0.99).contains(&momentum) {
        return -1;
    }

    let mut ids = [0_usize; MAX_CALL_COUNT];
    let mut event_params = [[0.0_f64; MAX_MATRIX_ELEMENTS]; MAX_CALL_COUNT];
    let mut event_gradients = [[0.0_f64; MAX_MATRIX_ELEMENTS]; MAX_CALL_COUNT];
    let mut seen = [false; MAX_GROUP_COUNT];
    let mut cursor = 7;
    for event in 0..call_count {
        let id = match exact_bounded_integer(values[cursor], 0, group_count - 1) {
            Some(value) => value, None => return -1,
        };
        ids[event] = id;
        seen[id] = true;
        cursor += 1;
        for element in 0..matrix_elements {
            let value = values[cursor + element];
            if !(-10.0..=10.0).contains(&value) { return -1; }
            event_params[event][element] = value;
        }
        cursor += matrix_elements;
        for element in 0..matrix_elements {
            let value = values[cursor + element];
            if !(-0.01..=0.01).contains(&value) { return -1; }
            event_gradients[event][element] = value;
        }
        cursor += matrix_elements;
    }
    if (0..group_count).any(|id| !seen[id]) { return -1; }

    let group_elements = group_count * matrix_elements;
    let output_elements = 2 * group_elements;
    if output.is_null() || output_capacity < output_elements { return -2; }

    let mut velocities = [0.0_f64; MAX_GROUP_MATRIX_ELEMENTS];
    let mut last_params = [0.0_f64; MAX_GROUP_MATRIX_ELEMENTS];
    for event in 0..call_count {
        let id = ids[event];
        let state_offset = id * matrix_elements;
        let orthogonalized = orthogonalize(&event_gradients[event][..matrix_elements], rows, columns, ns_steps);
        for element in 0..matrix_elements {
            let state_index = state_offset + element;
            velocities[state_index] = rounded_add(
                rounded_multiply(momentum, velocities[state_index]), orthogonalized[element]);
            last_params[state_index] = rounded_subtract(
                event_params[event][element],
                rounded_multiply(learning_rate, velocities[state_index]));
        }
    }

    for index in 0..group_elements {
        unsafe {
            *output.add(index) = last_params[index];
            *output.add(group_elements + index) = velocities[index];
        }
    }
    output_elements as i64
}
