fn digit_counts(mut value: i64) -> [u8; 10] {
    let mut counts = [0u8; 10];
    while value > 0 { counts[(value % 10) as usize] += 1; value /= 10; }
    counts
}
fn same_digits(left: i64, right: i64) -> bool { digit_counts(left) == digit_counts(right) }

#[no_mangle]
pub extern "C" fn problem52(unused: i64) -> i64 {
    if unused != 0 { return -1; }
    let mut value = 1i64;
    loop {
        let mut matches = true;
        for multiplier in 2..=6 { if !same_digits(value, value * multiplier) { matches = false; } }
        if matches { return value; }
        value += 1;
    }
}
