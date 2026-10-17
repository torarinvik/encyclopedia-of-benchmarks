const MAX_N: i64 = 100;
const MAX_VALID_INPUT_LENGTH: usize = 1;
const MAX_INPUT_LENGTH: usize = MAX_VALID_INPUT_LENGTH + 1;

#[no_mangle]
pub unsafe extern "C" fn euler_problem_6(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < MAX_VALID_INPUT_LENGTH || length > MAX_INPUT_LENGTH {
        return -1;
    }
    if length != MAX_VALID_INPUT_LENGTH {
        return -1;
    }
    let n = *input;
    if !(1..=MAX_N).contains(&n) {
        return -1;
    }

    let mut sum = 0_i64;
    let mut sum_of_squares = 0_i64;
    for value in 1..=n {
        sum += value;
        sum_of_squares += value * value;
    }
    sum * sum - sum_of_squares
}
