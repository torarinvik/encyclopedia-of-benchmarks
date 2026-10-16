/// Return the final term of a bounded N-bonacci sequence.
#[no_mangle]
pub extern "C" fn n_bonacci(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let order_value = values[0];
    let count_value = values[1];
    if order_value < 1 || count_value <= order_value || count_value > 64 { return -1; }
    let order = order_value as usize;
    let count = count_value as usize;
    let mut terms = [0i64; 64];
    terms[order - 1] = 1;
    terms[order] = 1;
    for index in order + 1..count {
        terms[index] = 2 * terms[index - 1] - terms[index - 1 - order];
    }
    terms[count - 1]
}
