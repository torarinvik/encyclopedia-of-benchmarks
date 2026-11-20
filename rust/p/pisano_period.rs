const MAX_MODULUS: i64 = 64;

#[no_mangle]
pub unsafe extern "C" fn pisano_period(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=2).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 1 || !(1..=MAX_MODULUS).contains(&values[0]) { return -1; }
    let modulus = values[0];
    let initial_next = 1_i64 % modulus;
    let mut previous = 0_i64;
    let mut current = initial_next;
    for period in 1..=6 * modulus {
        let next = (previous + current) % modulus;
        previous = current;
        current = next;
        if previous == 0 && current == initial_next { return period; }
    }
    -1
}
