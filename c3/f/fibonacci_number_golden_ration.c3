module fibonacci_number_golden_ration;

extern fn double sqrt(double value);
extern fn double pow(double base, double exponent);
extern fn double floor(double value);

fn long fibonacci_number_golden_ration(long input) @export("fibonacci_number_golden_ration") {
    if (input < 0 || input > 70) return -1;
    if (input <= 1) return input;

    double sqrt5 = sqrt(5.0);
    double phi = (1.0 + sqrt5) / 2.0;
    double psi = (1.0 - sqrt5) / 2.0;
    double result = (pow(phi, (double)input) - pow(psi, (double)input)) / sqrt5;
    return (long)floor(result + 0.5);
}
