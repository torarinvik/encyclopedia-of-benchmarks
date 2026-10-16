const MAX_DIGITS: usize = 19;
const MAX_DIGIT_SUM: usize = 171;
const MAX_INPUT_LENGTH: usize = 4;
const MIN_BOUND: i64 = -1;
const MAX_BOUND: i64 = 1_000_000_000_000_000_000;

fn count_up_to(mut bound: i64, target: usize) -> i64 {
    if bound < 0 { return 0; }
    let mut digits = [0_usize; MAX_DIGITS];
    let mut digit_count = 0;
    loop {
        digits[digit_count] = (bound % 10) as usize;
        digit_count += 1;
        bound /= 10;
        if bound == 0 { break; }
    }

    let mut loose = [0_i64; MAX_DIGIT_SUM + 1];
    let mut tight = [0_i64; MAX_DIGIT_SUM + 1];
    tight[0] = 1;
    while digit_count > 0 {
        digit_count -= 1;
        let limit = digits[digit_count];
        let mut next_loose = [0_i64; MAX_DIGIT_SUM + 1];
        let mut next_tight = [0_i64; MAX_DIGIT_SUM + 1];
        for sum in 0..=target {
            for digit in 0..=9 {
                if sum + digit > target { break; }
                next_loose[sum + digit] += loose[sum];
            }
            for digit in 0..=limit {
                if sum + digit > target { break; }
                if digit == limit { next_tight[sum + digit] += tight[sum]; }
                else { next_loose[sum + digit] += tight[sum]; }
            }
        }
        loose = next_loose;
        tight = next_tight;
    }
    loose[target] + tight[target]
}

#[no_mangle]
pub unsafe extern "C" fn digit_dp(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length > MAX_INPUT_LENGTH || length != 3 { return -1; }
    let lower = *input;
    let upper = *input.add(1);
    let target_value = *input.add(2);
    if lower < MIN_BOUND || lower > MAX_BOUND || upper < MIN_BOUND || upper > MAX_BOUND
        || target_value < i32::MIN as i64 || target_value > i32::MAX as i64 { return -1; }
    if lower > upper || target_value < 0 || target_value > MAX_DIGIT_SUM as i64 { return 0; }
    let target = target_value as usize;
    count_up_to(upper, target) - count_up_to(lower - 1, target)
}
