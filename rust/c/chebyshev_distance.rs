/// Return the greatest absolute coordinate difference from packed points.
#[no_mangle]
pub unsafe extern "C" fn chebyshev_distance(values: *const i64, length: usize) -> i64 {
    if length < 3 { return -1; }
    let dimension_value = *values;
    if !(1..=128).contains(&dimension_value) { return -1; }
    let dimension = dimension_value as usize;
    if length != 1 + 2 * dimension { return -1; }
    let mut maximum = 0_i64;
    for i in 0..dimension {
        let a = *values.add(1 + i);
        let b = *values.add(1 + dimension + i);
        if !(-1_000_000_000..=1_000_000_000).contains(&a)
            || !(-1_000_000_000..=1_000_000_000).contains(&b) { return -1; }
        let difference = (a - b).abs();
        if difference > maximum { maximum = difference; }
    }
    maximum
}
