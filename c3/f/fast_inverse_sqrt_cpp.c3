module fast_inverse_sqrt_cpp;

const double MIN_VALUE = 1e-6;
const double MAX_VALUE = 1e6;

fn double fast_inverse_sqrt_cpp(double value) @export("fast_inverse_sqrt_cpp") {
    if (value != value || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    double y = value;
    double x2 = y * 0.5;
    long bits = bitcast(y, long);
    bits = 0x5fe6eb50c7b537a9 - (bits >> 1);
    ulong seed_bits = (ulong)bits;
    y = bitcast(seed_bits, double);
    y = y * (1.5 - (x2 * y * y));
    y = y * (1.5 - (x2 * y * y));
    return y;
}
