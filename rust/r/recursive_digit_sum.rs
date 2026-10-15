/// Compute the source's repeated-digit-sum result from n and k.
fn digit_sum(mut number: i64) -> i64 {
    let mut sum = 0;
    while number != 0 {
        sum += number % 10;
        number /= 10;
    }
    sum
}

#[no_mangle]
pub extern "C" fn recursive_digit_sum(number: i64, repetitions: i64) -> i64 {
    if number < 0 || repetitions < 0 || repetitions > 1_000_000 { return -1; }
    let mut total = digit_sum(number) * repetitions;
    while total >= 10 { total = digit_sum(total); }
    total
}
