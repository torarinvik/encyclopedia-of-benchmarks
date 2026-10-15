/// Preserve the pinned JavaScript FriendlyNumbers divisor-loop behavior.
fn abundancy_index(number: u64) -> f64 {
    let mut sum = number;
    let mut divisor = 1u64;
    while divisor * 2 < number {
        if number % divisor == 0 { sum += divisor; }
        divisor += 1;
    }
    sum as f64 / number as f64
}

#[no_mangle]
pub extern "C" fn friendly_numbers(first: u64, second: u64) -> i64 {
    if first == 0 || second == 0 || first == second || first > 1000 || second > 1000 { return -1; }
    if abundancy_index(first) == abundancy_index(second) { 1 } else { 0 }
}
