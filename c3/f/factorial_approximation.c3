module factorial_approximation;

extern fn double sqrt(double value);
extern fn double pow(double base, double exponent);

fn double factorial_approximation(double x) @export("factorial_approximation") {
    if (!(x >= 0.0 && x <= 170.0)) return -1.0;
    return sqrt(3.141592653589793) * pow(x / 2.718281828459045, x)
        * pow(8.0 * pow(x, 3.0) + 4.0 * pow(x, 2.0) + x + 1.0 / 30.0, 1.0 / 6.0);
}
