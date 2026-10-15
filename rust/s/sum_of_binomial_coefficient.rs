/// Sum of a full binomial row, computed as 2^n.
#[no_mangle]
pub extern "C" fn sum_of_binomial_coefficient(n: i64) -> i64 {
    if !(0..=30).contains(&n) {
        return -1;
    }
    1i64 << n
}
