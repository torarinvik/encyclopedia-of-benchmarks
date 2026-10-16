#[no_mangle]
pub unsafe extern "C" fn reversort_cost(values: *const i64, length: usize) -> i64 {
    if length > 256 {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input.iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) {
        return -1;
    }
    let mut working = [0_i64; 256];
    working[..length].copy_from_slice(input);
    let mut cost = 0_i64;
    for index in 0..length.saturating_sub(1) {
        let mut minimum = index;
        for probe in index + 1..length {
            if working[probe] < working[minimum] {
                minimum = probe;
            }
        }
        working[index..=minimum].reverse();
        cost += (minimum - index + 1) as i64;
    }
    cost
}
