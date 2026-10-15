/// Portable zero-based Tribonacci recurrence for the shared i64 contract.
#[no_mangle]
pub extern "C" fn tribonacci(n: i64) -> i64 {
    if !(0..=73).contains(&n) {
        return -1;
    }
    if n == 0 {
        return 0;
    }
    if n <= 2 {
        return 1;
    }
    let (mut previous_three, mut previous_two, mut previous_one) = (0_i64, 1_i64, 1_i64);
    for _ in 3..=n {
        let next = previous_three + previous_two + previous_one;
        previous_three = previous_two;
        previous_two = previous_one;
        previous_one = next;
    }
    previous_one
}
