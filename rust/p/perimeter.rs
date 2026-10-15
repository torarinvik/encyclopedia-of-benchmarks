#[no_mangle]
pub unsafe extern "C" fn perimeter(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let data = std::slice::from_raw_parts(values, length);
    let sides = data[0];
    let side_length = data[1];
    if !(3..=256).contains(&sides) || !(1..=255).contains(&side_length) { return -1; }
    sides * side_length
}
