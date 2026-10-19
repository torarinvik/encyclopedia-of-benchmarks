const INPUT_COUNT: usize = 4;
const MAX_ROOTS: usize = 3;

fn solve_cubic(input: &[f64; INPUT_COUNT]) -> Option<([f64; MAX_ROOTS], usize)> {
    let [a, b, c, d] = *input;
    let a1 = b / a;
    let a2 = c / a;
    let a3 = d / a;
    let q = (a1 * a1 - 3.0 * a2) / 9.0;
    let r = (2.0 * a1 * a1 * a1 - 9.0 * a1 * a2 + 27.0 * a3) / 54.0;
    let discriminant = r * r - q * q * q;
    if discriminant == 0.0 {
        return None;
    }
    let mut roots = [0.0; MAX_ROOTS];
    if discriminant <= 0.0 {
        let pi = (-1.0_f64).acos();
        let theta = (r / (q * q * q).sqrt()).acos();
        roots[0] = -2.0 * q.sqrt() * (theta / 3.0).cos() - a1 / 3.0;
        roots[1] = -2.0 * q.sqrt() * ((theta + 2.0 * pi) / 3.0).cos() - a1 / 3.0;
        roots[2] = -2.0 * q.sqrt() * ((theta + 4.0 * pi) / 3.0).cos() - a1 / 3.0;
        Some((roots, 3))
    } else {
        let mut root = (discriminant.sqrt() + r.abs()).powf(1.0 / 3.0);
        root += q / root;
        root *= if r < 0.0 { 1.0 } else { -1.0 };
        roots[0] = root - a1 / 3.0;
        Some((roots, 1))
    }
}

#[no_mangle]
pub unsafe extern "C" fn mibench_automotive_basicmath_cubic(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != INPUT_COUNT {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if values.iter().any(|value| !value.is_finite() || *value < -100.0 || *value > 100.0) {
        return -1;
    }
    if values[0] > -1.0 && values[0] < 1.0 {
        return -1;
    }
    let coefficients: &[f64; INPUT_COUNT] = values.try_into().unwrap();
    let Some((roots, count)) = solve_cubic(coefficients) else {
        return -1;
    };
    if output.is_null() || output_capacity < count {
        return -2;
    }
    std::ptr::copy_nonoverlapping(roots.as_ptr(), output, count);
    count as i64
}
