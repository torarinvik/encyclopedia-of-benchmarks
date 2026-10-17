unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    for (index, byte) in value.to_le_bytes().iter().enumerate() { *output.add(offset + index) = *byte; }
}

#[no_mangle]
pub unsafe extern "C" fn shree_dharacharya_formula(input: *const i64, length: usize,
                                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    for index in 0..3 {
        let value = *input.add(index);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
    }
    let a_value = *input;
    if a_value == 0 { return -1; }
    let a = a_value as f64;
    let b = *input.add(1) as f64;
    let c = *input.add(2) as f64;
    let discriminant = b * b - 4.0 * a * c;
    if discriminant < 0.0 { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let root = discriminant.sqrt();
    let denominator = 2.0 * a;
    let first = (-b + root) / denominator;
    let second = (-b - root) / denominator;
    write_f64_le(output, 0, first);
    write_f64_le(output, 8, second);
    16
}
