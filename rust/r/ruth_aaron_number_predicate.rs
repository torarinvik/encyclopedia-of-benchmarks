const MAX_N: i64 = 100_000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn factor_sum_counted(mut value: i64) -> i64 {
    let mut sum = 0_i64;
    let mut divisor = 2_i64;
    while divisor <= value / divisor {
        while value % divisor == 0 {
            sum += divisor;
            value /= divisor;
        }
        divisor += 1;
    }
    if value > 1 { sum += value; }
    sum
}

#[no_mangle]
pub unsafe extern "C" fn ruth_aaron_number_predicate(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    if length != 1 { return -1; }
    let n = unsafe { *input };
    if !(1..=MAX_N).contains(&n) { return -1; }
    if factor_sum_counted(n) == factor_sum_counted(n + 1) { 1 } else { 0 }
}
