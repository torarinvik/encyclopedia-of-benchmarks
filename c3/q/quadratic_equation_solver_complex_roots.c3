module quadratic_equation_solver_complex_roots;

extern fn double sqrt(double value);

const long COEFFICIENT_LIMIT = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double quadratic_equation_solver_complex_roots_impl(long* values, usz length) {
    if (values == null || length != 4) return INVALID_RESULT;
    long a = values[0], b = values[1], c = values[2], component = values[3];
    if (a == 0 || a < -COEFFICIENT_LIMIT || a > COEFFICIENT_LIMIT ||
        b < -COEFFICIENT_LIMIT || b > COEFFICIENT_LIMIT ||
        c < -COEFFICIENT_LIMIT || c > COEFFICIENT_LIMIT ||
        component < 0 || component > 3) return INVALID_RESULT;

    long discriminant = b * b - 4 * a * c;
    double denominator = 2.0 * (double)a;
    if (discriminant > 0) {
        if (component >= 2) return INVALID_RESULT;
        double square_root = sqrt((double)discriminant);
        if (component == 0) return (-(double)b + square_root) / denominator;
        return (-(double)b - square_root) / denominator;
    }
    if (discriminant == 0) {
        if (component == 0) return -(double)b / denominator;
        return INVALID_RESULT;
    }

    if (component < 2) return -(double)b / denominator;
    double imaginary = sqrt((double)(-discriminant)) / denominator;
    if (component == 2) return imaginary;
    return -imaginary;
}

fn double quadratic_equation_solver_complex_roots(long* values, usz length)
    @export("quadratic_equation_solver_complex_roots") {
    return quadratic_equation_solver_complex_roots_impl(values, length);
}
