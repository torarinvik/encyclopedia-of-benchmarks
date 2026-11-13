module adaptive_simpson_quadrature;

extern fn double sin(double value);
extern fn double fabs(double value);

const usz MAX_INPUT_LENGTH = 6;

fn bool exact_integer(double x, long lo, long hi) {
    return x == x && x >= (double)lo && x <= (double)hi && (double)(long)x == x;
}

fn double sample(long id, double x) {
    if (id == 0) return x * x * x * x;
    if (id == 1) return sin(x);
    return 1.0 / (1.0 + x * x);
}

fn double simpson(double a, double b, double fa, double fm, double fb) {
    return (b - a) * (fa + 4.0 * fm + fb) / 6.0;
}

fn double refine(long id, double a, double b, double fa, double fm, double fb,
                 double whole, double tol, long depth) {
    double mid = (a + b) * 0.5;
    double lm = (a + mid) * 0.5;
    double rm = (mid + b) * 0.5;
    double flm = sample(id, lm);
    double frm = sample(id, rm);
    double left = simpson(a, mid, fa, flm, fm);
    double right = simpson(mid, b, fm, frm, fb);
    double delta = left + right - whole;
    if (depth == 0 || fabs(delta) <= 15.0 * tol) return left + right + delta / 15.0;
    return refine(id, a, mid, fa, flm, fm, left, tol * 0.5, depth - 1) +
           refine(id, mid, b, fm, frm, fb, right, tol * 0.5, depth - 1);
}

fn long adaptive_simpson_quadrature(double* input, usz input_length,
                                    double* output, usz output_capacity)
    @export("adaptive_simpson_quadrature") {
    if (input == null || input_length != 5 || input_length > MAX_INPUT_LENGTH) return -1L;
    double idf = input[0]; double af = input[1]; double bf = input[2];
    double ef = input[3]; double df = input[4];
    if (!exact_integer(idf, 0, 2) || !exact_integer(af, -2000000, 2000000) ||
        !exact_integer(bf, -2000000, 2000000) || !exact_integer(ef, 7, 8) ||
        !exact_integer(df, 8, 12) || af > bf) return -1L;
    if (output == null || output_capacity < 1) return -2L;
    long id = (long)idf; long exponent = (long)ef; long depth = (long)df;
    double a = af / 1000000.0; double b = bf / 1000000.0;
    double tol = 1.0;
    for (long i = 0; i < exponent; i++) tol *= 0.1;
    double result = 0.0;
    if (a != b) {
        double mid = (a + b) * 0.5;
        double fa = sample(id, a); double fm = sample(id, mid); double fb = sample(id, b);
        result = refine(id, a, b, fa, fm, fb, simpson(a, b, fa, fm, fb), tol, depth);
    }
    if (!(result == result) || result > 1e308 || result < -1e308) return -1L;
    output[0] = result;
    return 1L;
}
