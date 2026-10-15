module exponential_function;

const double INVALID_RESULT = -1.0e300;
extern fn double pow(double base, double exponent);

fn double exponential_function(double power, double term_count) @export("exponential_function") {
    if (!(power >= -10.0 && power <= 10.0 && term_count >= 0.0 && term_count <= 32.0)) return INVALID_RESULT;
    int n = (int)term_count;
    if ((double)n != term_count) return INVALID_RESULT;
    if (n == 0) return 1.0;

    double output = 0.0;
    double factorial = 1.0;
    for (int i = 0; i < n; i += 1) {
        output += pow(power, (double)i) / factorial;
        factorial *= (double)(i + 1);
    }
    return output;
}
