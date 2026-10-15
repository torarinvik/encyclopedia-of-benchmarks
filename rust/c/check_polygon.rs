/// Check whether positive side lengths can form a non-degenerate polygon.
#[no_mangle]
pub unsafe extern "C" fn check_polygon(
    values: *const i64,
    length: usize,
    _output: *mut u8,
    _output_capacity: usize,
) -> i64 {
    if values.is_null() || !(3..=256).contains(&length) {
        return -1;
    }
    let sides = std::slice::from_raw_parts(values, length);
    let mut total = 0_i64;
    let mut maximum = 0_i64;
    for &side in sides {
        if !(1..=1_000_000_000).contains(&side) {
            return -1;
        }
        total += side;
        maximum = maximum.max(side);
    }
    if maximum < total - maximum { 1 } else { 0 }
}
