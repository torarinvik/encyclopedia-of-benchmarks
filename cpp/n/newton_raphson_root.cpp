#include <cmath>

extern "C" double newton_raphson_root(double x0) noexcept {
    if (!std::isfinite(x0) || x0 < 1.0 || x0 > 4.0) return -1e300;
    float x = static_cast<float>(x0);
    for (int i = 0; i < 1000; ++i) {
        volatile float square = x * x;
        volatile float residual = square - 3.0f;
        if (std::fabs(residual) <= 1e-6f) return static_cast<double>(x);
        volatile float derivative = 2.0f * x;
        if (derivative == 0.0f) return -1e300;
        volatile float quotient = residual / derivative;
        volatile float next = x - quotient;
        x = next;
    }
    return static_cast<double>(x);
}
