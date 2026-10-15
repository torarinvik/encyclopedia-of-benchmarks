/// Check whether a square can be split into two parts that sum to n.
#[no_mangle]
pub extern "C" fn kaprekar_number(number: i64) -> i64 {
    if number < 1 { return 0; }
    if number > 2_000_000_000 { return -1; }
    if number == 1 { return 1; }
    let square = number * number;
    let mut split = 10_i64;
    while split <= square {
        let right = square % split;
        if right > 0 && square / split + right == number { return 1; }
        if split > square / 10 { break; }
        split *= 10;
    }
    0
}
