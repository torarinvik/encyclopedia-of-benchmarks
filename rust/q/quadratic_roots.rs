const COEFFICIENT_LIMIT: i64 = 1_000_000;

unsafe fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for byte in 0..8 {
        *output.add(offset + byte) = bytes[byte];
    }
}

#[no_mangle]
pub unsafe extern "C" fn quadratic_roots(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let ai = *values;
    let bi = *values.add(1);
    let ci = *values.add(2);
    if ai == 0 || ai < -COEFFICIENT_LIMIT || ai > COEFFICIENT_LIMIT ||
        bi < -COEFFICIENT_LIMIT || bi > COEFFICIENT_LIMIT ||
        ci < -COEFFICIENT_LIMIT || ci > COEFFICIENT_LIMIT { return -1; }

    let a = ai as f64;
    let b = bi as f64;
    let c = ci as f64;
    let discriminant = b * b - 4.0 * a * c;
    if discriminant < 0.0 { return 0; }

    if discriminant == 0.0 {
        if output.is_null() || output_capacity < 8 { return -2; }
        write_f64_le(output, 0, -b / (2.0 * a));
        return 1;
    }

    if output.is_null() || output_capacity < 16 { return -2; }
    let square_root = discriminant.sqrt();
    write_f64_le(output, 0, (-b + square_root) / (2.0 * a));
    write_f64_le(output, 8, (-b - square_root) / (2.0 * a));
    2
}

