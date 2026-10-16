module sqrt;

const double MIN_VALUE = 1e-6;
const double MAX_VALUE = 1e6;

fn float newton_step(float x2, float y) {
    float product1 = x2 * y;
    float product2 = product1 * y;
    float correction = 1.5f - product2;
    return y * correction;
}

// Reciprocal of the pinned Go binary32 fast-inverse-square-root result.
fn double go_sqrt_f32(double value) @export("go_sqrt_f32") {
    if (value != value || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    float number = (float)value;
    float x2 = number * 0.5f;
    uint bits = @bitcast(uint, number);
    bits = 0x5f3759df - (bits >> 1);
    float inverse_root = @bitcast(float, bits);
    inverse_root = newton_step(x2, inverse_root);
    inverse_root = newton_step(x2, inverse_root);
    float root = 1.0f / inverse_root;
    return (double)root;
}
