#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MIN_DEGREE = 2, MAX_DEGREE = 6, MAX_INPUT = 12, MAX_PARSEABLE = 13 };
typedef struct { double re, im; } cx;

static cx c_add(cx a, cx b) { return (cx){a.re + b.re, a.im + b.im}; }
static cx c_sub(cx a, cx b) { return (cx){a.re - b.re, a.im - b.im}; }
static cx c_mul(cx a, cx b) { return (cx){a.re*b.re - a.im*b.im, a.re*b.im + a.im*b.re}; }
static cx c_div(cx a, cx b) {
    double d = b.re*b.re + b.im*b.im;
    return (cx){(a.re*b.re + a.im*b.im)/d, (a.im*b.re - a.re*b.im)/d};
}
static double c_abs(cx a) { return hypot(a.re, a.im); }
static int c_finite(cx a) { return isfinite(a.re) && isfinite(a.im); }
static cx c_sqrt(cx a) {
    double m = c_abs(a);
    double re = sqrt(fmax(0.0, (m + a.re) * 0.5));
    double im = sqrt(fmax(0.0, (m - a.re) * 0.5));
    if (a.im < 0.0) im = -im;
    return (cx){re, im};
}
static int integer_field(double value, int low, int high, int *out) {
    if (!isfinite(value) || value < low || value > high || trunc(value) != value) return 0;
    *out = (int)value;
    return 1;
}
static void evaluate(const double *a, int n, cx z, cx *p, cx *dp, cx *ddp, double *scale) {
    *p = (cx){a[n], 0.0}; *dp = (cx){0.0, 0.0}; *ddp = (cx){0.0, 0.0};
    for (int k = n - 1; k >= 0; --k) {
        *ddp = c_add(c_mul(*ddp, z), (cx){2.0*dp->re, 2.0*dp->im});
        *dp = c_add(c_mul(*dp, z), *p);
        *p = c_add(c_mul(*p, z), (cx){a[k], 0.0});
    }
    double radius = c_abs(z);
    *scale = fabs(a[n]);
    for (int k = n - 1; k >= 0; --k) *scale = *scale * radius + fabs(a[k]);
}
static int solve(const double *a, int n, cx z, double tolerance, int iterations, cx *result) {
    for (int step = 0; step <= iterations; ++step) {
        if (!c_finite(z)) return -3;
        cx p, dp, ddp; double scale;
        evaluate(a, n, z, &p, &dp, &ddp, &scale);
        if (!c_finite(p) || !c_finite(dp) || !c_finite(ddp) || !isfinite(scale)) return -3;
        if (c_abs(p) <= tolerance * fmax(1.0, scale)) { *result = z; return 2; }
        if (step == iterations || (p.re == 0.0 && p.im == 0.0)) return -3;
        cx g = c_div(dp, p);
        cx h = c_sub(c_mul(g, g), c_div(ddp, p));
        cx radicand = c_mul((cx){(double)(n - 1), 0.0},
                            c_sub(c_mul((cx){(double)n, 0.0}, h), c_mul(g, g)));
        if (!c_finite(g) || !c_finite(h) || !c_finite(radicand)) return -3;
        cx root = c_sqrt(radicand);
        cx plus = c_add(g, root), minus = c_sub(g, root);
        cx denominator = c_abs(plus) >= c_abs(minus) ? plus : minus;
        double denominator_abs = c_abs(denominator);
        if (denominator_abs == 0.0 || !isfinite(denominator_abs)) return -3;
        cx correction = c_div((cx){(double)n, 0.0}, denominator);
        if (!c_finite(correction)) return -3;
        z = c_sub(z, correction);
    }
    return -3;
}

int64_t laguerre_complex_polynomial_root(const double *input, size_t input_length,
                                         double *output, size_t output_capacity) {
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE) return -1;
    int degree;
    if (!integer_field(input[0], MIN_DEGREE, MAX_DEGREE, &degree) || input_length != (size_t)degree + 6) return -1;
    double coefficients[MAX_DEGREE + 1];
    int decoded;
    for (int i = 0; i <= degree; ++i) {
        if (!integer_field(input[1 + i], -16, 16, &decoded)) return -1;
        coefficients[i] = (double)decoded;
    }
    if (coefficients[degree] == 0.0) return -1;
    int re_milli, im_milli, tolerance_micro, iterations;
    if (!integer_field(input[degree + 2], -4000, 4000, &re_milli) ||
        !integer_field(input[degree + 3], -4000, 4000, &im_milli) ||
        !integer_field(input[degree + 4], 1, 1000, &tolerance_micro) ||
        !integer_field(input[degree + 5], 8, 128, &iterations)) return -1;
    if (output == NULL || output_capacity < 2) return -2;
    cx result;
    int status = solve(coefficients, degree, (cx){re_milli/1000.0, im_milli/1000.0},
                       tolerance_micro/1000000.0, iterations, &result);
    if (status != 2 || !c_finite(result)) return -3;
    output[0] = result.re; output[1] = result.im;
    return 2;
}
