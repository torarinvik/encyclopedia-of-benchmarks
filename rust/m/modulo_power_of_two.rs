/// Java-compatible low-bit mask for a signed 32-bit input and exponent 1..31.
#[no_mangle]
pub unsafe extern "C" fn modulo_power_of_two(values: *const i64, length: usize) -> i64 {
    if length != 2 || values.is_null() { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let x = values[0];
    let exponent = values[1];
    if !(i32::MIN as i64..=i32::MAX as i64).contains(&x) || !(1..=31).contains(&exponent) { return -1; }
    let mask = (1i64 << exponent) - 1;
    x & mask
}
