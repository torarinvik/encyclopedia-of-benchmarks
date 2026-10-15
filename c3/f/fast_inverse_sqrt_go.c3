module fast_inverse_sqrt_go;

const double MIN_VALUE = 1e-6;
const double MAX_VALUE = 1e6;

fn float newton_step(float x2, float y) {
    float product1 = x2 * y;
    float product2 = product1 * y;
    float correction = 1.5f - product2;
    return y * correction;
}

fn double fast_inverse_sqrt_go(double value) @export("fast_inverse_sqrt_go") {
    if (value != value || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    float number = (float)value;
    float x2 = number * 0.5f;
    uint bits = @bitcast(uint, number);
    bits = 0x5f3759df - (bits >> 1);
    float y = @bitcast(float, bits);
    y = newton_step(x2, y);
    y = newton_step(x2, y);
    return (double)y;
}
