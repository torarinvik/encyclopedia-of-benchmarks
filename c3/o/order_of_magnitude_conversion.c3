module order_of_magnitude_conversion;

extern fn double pow(double base, double exponent);

const double MAX_VALUE = 1e100;

fn int unit_exponent(double code) {
    if (code == 0.0) return 0;
    if (code == 1.0) return 3;
    if (code == 2.0) return 6;
    if (code == 3.0) return 9;
    if (code == 4.0) return 12;
    if (code == 5.0) return 15;
    if (code == 6.0) return 18;
    if (code == 7.0) return 21;
    if (code == 8.0) return 24;
    return -1;
}

// Preserve the source formula and operation order: value * 10^(from - to).
fn double order_of_magnitude_conversion(double value, double from_unit_code, double to_unit_code) @export("order_of_magnitude_conversion") {
    if (value != value || value < -MAX_VALUE || value > MAX_VALUE) return -1.0;
    int from_exp = unit_exponent(from_unit_code);
    int to_exp = unit_exponent(to_unit_code);
    if (from_exp < 0 || to_exp < 0) return -1.0;
    return value * pow(10.0, (double)(from_exp - to_exp));
}
