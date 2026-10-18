const INVALID_RESULT: i64 = -1;
const OUTPUT_ERROR: i64 = -2;
const INPUT_LENGTH: usize = 6;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 7;

fn in_range(value: f64, minimum: f64, maximum: f64) -> bool {
    value >= minimum && value <= maximum
}

#[no_mangle]
pub unsafe extern "C" fn sir(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < INPUT_LENGTH || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    if input_length != INPUT_LENGTH {
        return INVALID_RESULT;
    }

    let s = *input;
    let i = *input.add(1);
    let r = *input.add(2);
    let beta = *input.add(3);
    let k = *input.add(4);
    let time = *input.add(5);
    if !in_range(s, 0.0, 1_000_000.0)
        || !in_range(i, 0.0, 1_000_000.0)
        || !in_range(r, 0.0, 1_000_000.0)
        || !in_range(beta, 0.0, 0.001)
        || !in_range(k, 0.0, 1.0)
        || !in_range(time, 0.0, 140.0)
    {
        return INVALID_RESULT;
    }

    let d_s = ((-beta) * s) * i;
    let d_i_infection = (beta * s) * i;
    let d_i_recovery = k * i;
    let d_i = d_i_infection - d_i_recovery;
    let d_r = k * i;

    if output.is_null() || output_capacity < 3 {
        return OUTPUT_ERROR;
    }
    *output = d_s;
    *output.add(1) = d_i;
    *output.add(2) = d_r;
    3
}
