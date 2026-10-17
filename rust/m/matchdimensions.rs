/// Compare the dimensions of two matrices represented by four integers.
#[no_mangle]
pub extern "C" fn matchdimensions(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 4 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, 4) };
    if values.iter().any(|&value| !(0..=65535).contains(&value)) { return -1; }
    if values[0] == values[2] && values[1] == values[3] { 1 } else { 0 }
}
