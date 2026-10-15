#[no_mangle]
pub extern "C" fn sum_of_odd_numbers(n: i64) -> i64 {
    if !(0..=46_340).contains(&n) {
        return -1;
    }
    n * n
}
