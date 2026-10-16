module newton_raphson_root;

fn double newton_raphson_root(double x0) @export("newton_raphson_root") {
    if (x0 != x0 || x0 < 1.0 || x0 > 4.0) return -1e300;
    float x = (float)x0;
    for (int i = 0; i < 1000; i += 1) {
        float residual = x * x - 3.0f;
        if (residual >= -1e-6f && residual <= 1e-6f) return (double)x;
        float derivative = 2.0f * x;
        if (derivative == 0.0f) return -1e300;
        x = x - residual / derivative;
    }
    return (double)x;
}
