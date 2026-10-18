const MAX_PARSEABLE_INPUT_LENGTH: usize = 22;
const MAX_DEGREE: usize = 8;
const MAX_OUTPUT_ELEMENTS: usize = 17;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn single_indeterminate_operations(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values.iter().any(|value| !value.is_finite()) { return -1; }
    let operation = match exact_integer(values[0], 0, 5) { Some(value) => value as usize, None => return -1 };

    let mut cursor = 1;
    let mut degree_a = 0_usize;
    let mut coefficients_a = [0.0_f64; MAX_DEGREE + 1];
    let mut degree_b = 0_usize;
    let mut coefficients_b = [0.0_f64; MAX_DEGREE + 1];
    let mut parameter = 0.0_f64;

    let degree = match exact_integer(values[cursor], 0, MAX_DEGREE as i64) { Some(value) => value as usize, None => return -1 };
    cursor += 1;
    degree_a = degree;
    if cursor + degree + 1 > input_length { return -1; }
    for index in 0..=degree {
        let value = values[cursor + index];
        if !(-10.0..=10.0).contains(&value) { return -1; }
        coefficients_a[index] = value;
    }
    cursor += degree + 1;

    if operation <= 2 {
        let other_degree = match exact_integer(values.get(cursor).copied().unwrap_or(f64::NAN), 0, MAX_DEGREE as i64) {
            Some(value) => value as usize, None => return -1,
        };
        cursor += 1;
        degree_b = other_degree;
        if cursor + other_degree + 1 > input_length { return -1; }
        for index in 0..=other_degree {
            let value = values[cursor + index];
            if !(-10.0..=10.0).contains(&value) { return -1; }
            coefficients_b[index] = value;
        }
        cursor += other_degree + 1;
        if cursor != input_length { return -1; }
    } else if operation == 3 || operation == 5 {
        if cursor + 1 != input_length { return -1; }
        parameter = values[cursor];
        if operation == 3 {
            if !(-2.0..=2.0).contains(&parameter) { return -1; }
        } else if !(-10.0..=10.0).contains(&parameter) { return -1; }
        cursor += 1;
    } else if cursor != input_length { return -1; }

    let mut staged = [0.0_f64; MAX_OUTPUT_ELEMENTS];
    let result_length;
    match operation {
        0 => {
            let result_degree = degree_a.max(degree_b);
            result_length = result_degree + 1;
            if degree_a > degree_b {
                staged[..result_length].copy_from_slice(&coefficients_a[..result_length]);
                for index in 0..=degree_b { staged[index] += coefficients_b[index]; }
            } else {
                staged[..result_length].copy_from_slice(&coefficients_b[..result_length]);
                for index in 0..=degree_a { staged[index] += coefficients_a[index]; }
            }
        }
        1 => {
            let mut negated_b = [0.0_f64; MAX_DEGREE + 1];
            for index in 0..=degree_b { negated_b[index] = coefficients_b[index] * -1.0; }
            let result_degree = degree_a.max(degree_b);
            result_length = result_degree + 1;
            if degree_a > degree_b {
                staged[..result_length].copy_from_slice(&coefficients_a[..result_length]);
                for index in 0..=degree_b { staged[index] += negated_b[index]; }
            } else {
                staged[..result_length].copy_from_slice(&negated_b[..result_length]);
                for index in 0..=degree_a { staged[index] += coefficients_a[index]; }
            }
        }
        2 => {
            result_length = degree_a + degree_b + 1;
            for left in 0..=degree_a {
                for right in 0..=degree_b {
                    staged[left + right] += coefficients_a[left] * coefficients_b[right];
                }
            }
        }
        3 => {
            result_length = 1;
            for index in 0..=degree_a {
                staged[0] += coefficients_a[index] * parameter.powi(index as i32);
            }
        }
        4 => {
            result_length = degree_a;
            for index in 0..degree_a { staged[index] = coefficients_a[index + 1] * (index + 1) as f64; }
        }
        _ => {
            result_length = degree_a + 2;
            staged[0] = parameter;
            for index in 0..=degree_a { staged[index + 1] = coefficients_a[index] / (index + 1) as f64; }
        }
    }
    if staged[..result_length].iter().any(|value| !value.is_finite()) { return -1; }
    if output.is_null() || output_capacity < result_length { return -2; }
    for index in 0..result_length { *output.add(index) = staged[index]; }
    result_length as i64
}
