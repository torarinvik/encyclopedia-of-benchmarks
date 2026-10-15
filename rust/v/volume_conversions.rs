const INVALID_RESULT: i64 = -1;
const MAX_VALUE: i64 = 1000;

fn unit_factor_to_cubic_meters(unit: i64) -> f64 {
    if unit == 1 { 0.001 } else { 1.0 }
}

#[no_mangle]
pub unsafe extern "C" fn volume_conversions(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, 3);
    let (value, from_unit, to_unit) = (values[0], values[1], values[2]);
    if !(0..=MAX_VALUE).contains(&value)
        || !(0..=2).contains(&from_unit)
        || !(0..=2).contains(&to_unit)
        || from_unit == to_unit { return INVALID_RESULT; }
    if capacity < 8 || output.is_null() { return -2; }
    let cubic_meters = (value as f64) * unit_factor_to_cubic_meters(from_unit);
    let converted = cubic_meters / unit_factor_to_cubic_meters(to_unit);
    std::ptr::copy_nonoverlapping(converted.to_le_bytes().as_ptr(), output, 8);
    8
}
