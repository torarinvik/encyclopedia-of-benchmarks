module shreedharacharya;
import "math";

const double MAX_COEFFICIENT = 1000000.0;
const double MIN_ABS_LEADING_COEFFICIENT = 0.000001;

fn long shreedharacharya(double* input, usz input_length,
        double* output, usz output_capacity) @export("shreedharacharya") {
    if (input == null || input_length != 3) return -1;
    double a = input[0], b = input[1], c = input[2];
    if (a != a || b != b || c != c ||
        a < -MAX_COEFFICIENT || a > MAX_COEFFICIENT ||
        a > -MIN_ABS_LEADING_COEFFICIENT && a < MIN_ABS_LEADING_COEFFICIENT ||
        b < -MAX_COEFFICIENT || b > MAX_COEFFICIENT ||
        c < -MAX_COEFFICIENT || c > MAX_COEFFICIENT) return -1;

    double discriminant = b * b - 4.0 * a * c;
    double[2] roots;
    usz count = 0;
    if (discriminant == 0.0) {
        roots[count++] = -b / (2.0 * a);
    } else if (discriminant > 0.0) {
        double square_root = math.sqrt(discriminant);
        double denominator = 2.0 * a;
        roots[count++] = (-b + square_root) / denominator;
        roots[count++] = (-b - square_root) / denominator;
    }
    for (usz index = 0; index < count; index++)
        if (roots[index] != roots[index]) return -1;
    if (output == null || output_capacity < count) return -2;
    for (usz index = 0; index < count; index++) output[index] = roots[index];
    return (long)count;
}
