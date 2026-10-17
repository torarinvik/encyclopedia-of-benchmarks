const MAX_COEFFICIENT: f64 = 1_000_000.0;
const MIN_ABS_LEADING_COEFFICIENT: f64 = 0.000001;

#[no_mangle]
pub unsafe extern "C" fn shreedharacharya(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_len != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, input_len);
    let (a, b, c) = (values[0], values[1], values[2]);
    if !a.is_finite() || !b.is_finite() || !c.is_finite()
        || a.abs() < MIN_ABS_LEADING_COEFFICIENT || a.abs() > MAX_COEFFICIENT
        || b.abs() > MAX_COEFFICIENT || c.abs() > MAX_COEFFICIENT {
        return -1;
    }

    let discriminant = b * b - 4.0 * a * c;
    let mut roots = [0.0f64; 2];
    let mut count = 0usize;
    if discriminant == 0.0 {
        roots[count] = -b / (2.0 * a);
        count += 1;
    } else if discriminant > 0.0 {
        let square_root = discriminant.sqrt();
        let denominator = 2.0 * a;
        roots[count] = (-b + square_root) / denominator;
        count += 1;
        roots[count] = (-b - square_root) / denominator;
        count += 1;
    }
    if roots[..count].iter().any(|root| !root.is_finite()) { return -1; }
    if output.is_null() || output_capacity < count { return -2; }
    for index in 0..count { *output.add(index) = roots[index]; }
    count as i64
}
