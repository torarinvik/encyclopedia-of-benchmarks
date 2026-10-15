const MAX_INPUT: i64 = 1_000_000_000;

#[no_mangle]
pub extern "C" fn reverse_number(mut number: i64) -> i64 {
    if !(0..=MAX_INPUT).contains(&number) { return -1; }
    let mut reversed = 0_i64;
    while number > 0 {
        reversed = reversed * 10 + number % 10;
        number /= 10;
    }
    reversed
}
