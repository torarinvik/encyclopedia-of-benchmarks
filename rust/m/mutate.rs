#[no_mangle]
pub unsafe extern "C" fn mutate(input: *const f64, length: usize,
                                output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 130 { return -1; }
    let mu = *input;
    let count_value = *input.add(1);
    if !mu.is_finite() || !(0.0..=1.0).contains(&mu) || !count_value.is_finite() ||
        count_value.fract() != 0.0 || !(0.0..=64.0).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 2 + 2 * count { return -1; }
    for index in 0..count {
        let gene = *input.add(2 + index);
        if gene != 0.0 && gene != 1.0 { return -1; }
    }
    for index in 0..count {
        let draw = *input.add(2 + count + index);
        if !draw.is_finite() || !(0.0..1.0).contains(&draw) { return -1; }
    }
    if output.is_null() || capacity < count { return -2; }
    for index in 0..count {
        let gene = *input.add(2 + index);
        let draw = *input.add(2 + count + index);
        *output.add(index) = if draw < mu { 1.0 - gene } else { gene };
    }
    count as i64
}
