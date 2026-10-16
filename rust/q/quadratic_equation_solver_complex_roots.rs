const COEFFICIENT_LIMIT: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn quadratic_equation_solver_complex_roots(
    values: *const i64, length: usize,
) -> f64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let a = *values;
    let b = *values.add(1);
    let c = *values.add(2);
    let component = *values.add(3);
    if a == 0 || a < -COEFFICIENT_LIMIT || a > COEFFICIENT_LIMIT ||
        b < -COEFFICIENT_LIMIT || b > COEFFICIENT_LIMIT ||
        c < -COEFFICIENT_LIMIT || c > COEFFICIENT_LIMIT ||
        component < 0 || component > 3 { return INVALID_RESULT; }

    let discriminant = b * b - 4 * a * c;
    let denominator = 2.0 * a as f64;
    if discriminant > 0 {
        if component >= 2 { return INVALID_RESULT; }
        let square_root = (discriminant as f64).sqrt();
        if component == 0 { return (-(b as f64) + square_root) / denominator; }
        return (-(b as f64) - square_root) / denominator;
    }
    if discriminant == 0 {
        if component == 0 { return -(b as f64) / denominator; }
        return INVALID_RESULT;
    }

    if component < 2 { return -(b as f64) / denominator; }
    let imaginary = ((-discriminant) as f64).sqrt() / denominator;
    if component == 2 { return imaginary; }
    -imaginary
}
