const MIN_SAMPLE_COUNT: usize = 2;
const MAX_SAMPLE_COUNT: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 66;
const MAX_OUTPUT_ELEMENTS: usize = 2;

#[inline]
fn exact_integer_in_range(value: f64, minimum: i64, maximum: i64) -> bool {
    value.is_finite()
        && value >= minimum as f64
        && value <= maximum as f64
        && value.trunc() == value
}

#[inline(never)]
fn rounded_divide(numerator: f64, denominator: f64) -> f64 {
    numerator / denominator
}

#[no_mangle]
pub unsafe extern "C" fn linearregressionrawr(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }

    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }

    if !exact_integer_in_range(
        values[0],
        MIN_SAMPLE_COUNT as i64,
        MAX_SAMPLE_COUNT as i64,
    ) {
        return -1;
    }
    let sample_count = values[0] as usize;
    if input_length != 1 + 2 * sample_count {
        return -1;
    }

    let mut predictor_sum: i64 = 0;
    let mut response_sum: i64 = 0;
    let mut cross_product_sum: i64 = 0;
    let mut predictor_square_sum: i64 = 0;
    let mut first_predictor: i64 = 0;
    let mut predictors_are_constant = true;

    for index in 0..sample_count {
        let predictor_value = values[1 + index];
        let response_value = values[1 + sample_count + index];
        if !exact_integer_in_range(predictor_value, -4, 4)
            || !exact_integer_in_range(response_value, -16, 16)
        {
            return -1;
        }

        let predictor = predictor_value as i64;
        let response = response_value as i64;
        if index == 0 {
            first_predictor = predictor;
        } else if predictor != first_predictor {
            predictors_are_constant = false;
        }

        predictor_sum += predictor;
        response_sum += response;
        cross_product_sum += predictor * response;
        predictor_square_sum += predictor * predictor;
    }

    if predictor_sum != 0 || predictors_are_constant || predictor_square_sum == 0 {
        return -1;
    }

    let staged = [
        rounded_divide(response_sum as f64, sample_count as f64),
        rounded_divide(cross_product_sum as f64, predictor_square_sum as f64),
    ];
    if output.is_null() || output_capacity < MAX_OUTPUT_ELEMENTS {
        return -2;
    }

    unsafe {
        for (index, value) in staged.iter().enumerate() {
            output.add(index).write(*value);
        }
    }
    MAX_OUTPUT_ELEMENTS as i64
}
