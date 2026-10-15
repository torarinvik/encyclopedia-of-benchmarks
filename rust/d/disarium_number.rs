/// Sum decimal digits raised to their one-based positions from the left.
#[no_mangle]
pub extern "C" fn disarium_number(number: i64) -> i64 {
    if !(1..=99_999_999).contains(&number) { return -1; }
    let mut digits = number;
    let mut count = 0_i64;
    while digits > 0 { count += 1; digits /= 10; }
    let mut position = count;
    let mut remaining = number;
    let mut sum = 0_i64;
    while remaining > 0 {
        let digit = remaining % 10;
        let mut power = 1_i64;
        for _ in 0..position { power *= digit; }
        sum += power;
        position -= 1;
        remaining /= 10;
    }
    if sum == number { 1 } else { 0 }
}
