module fast_inverse_square_root;

const double MIN_VALUE = 1e-6;
const double MAX_VALUE = 1e6;

// Match PHP's float32 pack/unpack using IEEE-754 bit casts.
fn double fast_inverse_square_root(double value) @export("fast_inverse_square_root") {
    if (value != value || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    float seed_input = (float)value;
    int bits = @bitcast(int, seed_input);
    bits = 0x5f3759df - (bits >> 1);
    float seed = @bitcast(float, bits);
    double y = (double)seed;
    return y * (1.5 - 0.5 * value * y * y);
}
