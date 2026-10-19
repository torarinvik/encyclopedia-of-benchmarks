module mibench_automotive_basicmath_cubic;

const INPUT_COUNT = 4;
const MAX_ROOTS = 3;

extern fn double acos(double value);
extern fn double cos(double value);
extern fn double sqrt(double value);
extern fn double pow(double value, double exponent);
extern fn double fabs(double value);

fn long solve_cubic(double* input, double* roots) {
    double a = input[0], b = input[1], c = input[2], d = input[3];
    double a1 = b / a, a2 = c / a, a3 = d / a;
    double q = (a1 * a1 - 3.0 * a2) / 9.0;
    double r = (2.0 * a1 * a1 * a1 - 9.0 * a1 * a2 + 27.0 * a3) / 54.0;
    double discriminant = r * r - q * q * q;
    if (discriminant == 0.0) return -1;
    if (discriminant <= 0.0) {
        double pi = acos(-1.0);
        double theta = acos(r / sqrt(q * q * q));
        roots[0] = -2.0 * sqrt(q) * cos(theta / 3.0) - a1 / 3.0;
        roots[1] = -2.0 * sqrt(q) * cos((theta + 2.0 * pi) / 3.0) - a1 / 3.0;
        roots[2] = -2.0 * sqrt(q) * cos((theta + 4.0 * pi) / 3.0) - a1 / 3.0;
        return 3;
    }
    double root = pow(sqrt(discriminant) + fabs(r), 1.0 / 3.0);
    root += q / root;
    root *= r < 0.0 ? 1.0 : -1.0;
    roots[0] = root - a1 / 3.0;
    return 1;
}

fn long mibench_automotive_basicmath_cubic(double* input, usz length,
    double* output, usz capacity) @export("mibench_automotive_basicmath_cubic") {
    if (input == null || length != INPUT_COUNT) return -1;
    for (usz index = 0; index < INPUT_COUNT; index++)
        if (!(input[index] >= -100.0 && input[index] <= 100.0)) return -1;
    if (input[0] > -1.0 && input[0] < 1.0) return -1;
    double[3] roots;
    long count = solve_cubic(input, &roots[0]);
    if (count < 0) return -1;
    if (output == null || capacity < (usz)count) return -2;
    for (usz index = 0; index < (usz)count; index++) output[index] = roots[index];
    return count;
}
