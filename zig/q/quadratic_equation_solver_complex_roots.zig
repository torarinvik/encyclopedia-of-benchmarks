const COEFFICIENT_LIMIT: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn quadratic_equation_solver_complex_roots(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4) return INVALID_RESULT;
    const a = values[0];
    const b = values[1];
    const c = values[2];
    const component = values[3];
    if (a == 0 or a < -COEFFICIENT_LIMIT or a > COEFFICIENT_LIMIT or
        b < -COEFFICIENT_LIMIT or b > COEFFICIENT_LIMIT or
        c < -COEFFICIENT_LIMIT or c > COEFFICIENT_LIMIT or
        component < 0 or component > 3) return INVALID_RESULT;

    const discriminant = b * b - 4 * a * c;
    const denominator = 2.0 * @as(f64, @floatFromInt(a));
    if (discriminant > 0) {
        if (component >= 2) return INVALID_RESULT;
        const square_root = @sqrt(@as(f64, @floatFromInt(discriminant)));
        if (component == 0) return (-@as(f64, @floatFromInt(b)) + square_root) / denominator;
        return (-@as(f64, @floatFromInt(b)) - square_root) / denominator;
    }
    if (discriminant == 0) {
        if (component == 0) return -@as(f64, @floatFromInt(b)) / denominator;
        return INVALID_RESULT;
    }

    if (component < 2) return -@as(f64, @floatFromInt(b)) / denominator;
    const imaginary = @sqrt(@as(f64, @floatFromInt(-discriminant))) / denominator;
    if (component == 2) return imaginary;
    return -imaginary;
}
