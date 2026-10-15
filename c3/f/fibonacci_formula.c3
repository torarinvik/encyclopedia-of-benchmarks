module fibonacci_formula;

extern fn double sqrt(double value);
extern fn double pow(double base, double exponent);

fn long fibonacci_formula(long input) @export("fibonacci_formula") {
    if (input < 0 || input > 35) return -1;
    uint n = (uint)input;
    float seq = (float)((1.0 / sqrt(5.0) * pow(((1.0 + sqrt(5.0)) / 2.0), (double)(n + 1)))
              - (1.0 / sqrt(5.0) * pow(((1.0 - sqrt(5.0)) / 2.0), (double)(n + 1))));
    return (long)(int)seq;
}
