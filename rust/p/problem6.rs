/// Return square(sum(1..=limit)) minus sum(square(1..=limit)).
#[no_mangle]
pub extern "C" fn problem6(limit: i64) -> i64 {
    if !(0..=100).contains(&limit) {
        return -1;
    }
    let mut sum = 0i64;
    let mut sum_of_squares = 0i64;
    for value in 1..=limit {
        sum += value;
        sum_of_squares += value * value;
    }
    sum * sum - sum_of_squares
}
