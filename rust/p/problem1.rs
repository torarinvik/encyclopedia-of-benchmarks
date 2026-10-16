/// Sum positive multiples of 3 or 5 strictly below the input limit.
#[no_mangle]
pub extern "C" fn problem1(limit: i64) -> i64 {
    if !(0..=100_000).contains(&limit) {
        return -1;
    }
    let mut sum = 0i64;
    for value in 1..limit {
        if value % 3 == 0 || value % 5 == 0 {
            sum += value;
        }
    }
    sum
}
