#[no_mangle]
pub unsafe extern "C" fn permutation_count(input: *const i64, input_length: usize) -> i64 {
    if input.is_null() || input_length != 2 { return -1; }
    let n = *input;
    let r = *input.add(1);
    if !(0..=18).contains(&n) || !(0..=18).contains(&r) { return -1; }
    let mut result = 1i64;
    if r > n {
        for factor in 2..=n { result *= factor; }
    } else {
        for i in 0..r { result *= n - i; }
    }
    result
}
