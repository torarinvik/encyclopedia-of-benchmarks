/// Check the Fibonacci square identity without overflowing signed 64-bit values.
fn square_i64(value: i64) -> bool {
    if value < 0 { return false; }
    let mut low = 0_i64;
    let mut high = 3_037_000_499_i64;
    while low <= high {
        let middle = low + (high - low) / 2;
        let square = middle * middle;
        if square == value { return true; }
        if square < value { low = middle + 1; }
        else { high = middle - 1; }
    }
    false
}

#[no_mangle]
pub extern "C" fn fibonacci_number_check(number: i64) -> i64 {
    if number < -1_300_000_000 || number > 1_300_000_000 { return -1; }
    let value = 5 * number * number;
    if square_i64(value + 4) || square_i64(value - 4) { 1 } else { 0 }
}
