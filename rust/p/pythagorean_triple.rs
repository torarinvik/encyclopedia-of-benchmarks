/// Check three signed integers with Java-compatible int-safe bounds.
#[no_mangle]
pub unsafe extern "C" fn pythagorean_triple(values: *const i64, length: usize) -> i64 {
    if length != 3 || values.is_null() { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let mut sides = [values[0], values[1], values[2]];
    if sides.iter().any(|&value| !(-32768..=32767).contains(&value)) { return -1; }
    if sides.iter().any(|&value| value <= 0) { return 0; }
    sides.sort_unstable();
    if sides[0] * sides[0] + sides[1] * sides[1] == sides[2] * sides[2] { 1 } else { 0 }
}
