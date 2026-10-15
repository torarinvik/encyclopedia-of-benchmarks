#[no_mangle]
pub extern "C" fn parity_outlier(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(3..=65).contains(&values[0]) || values[0] % 2 == 0 { return -1; }
    let count = values[0] as usize;
    if length != count + 1 { return -1; }
    let (mut evens, mut odds) = (0usize, 0usize);
    let (mut even_value, mut odd_value) = (0i64, 0i64);
    for &value in &values[1..] {
        if !(0..=2_147_483_647).contains(&value) { return -1; }
        if value % 2 == 0 { evens += 1; even_value = value; }
        else { odds += 1; odd_value = value; }
    }
    if evens == 1 && odds >= 2 { return even_value; }
    if odds == 1 && evens >= 2 { return odd_value; }
    -1
}
