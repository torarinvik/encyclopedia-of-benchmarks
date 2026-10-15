#include <cmath>

static double function_value(double x)
{
    return x * x - x;
}

extern "C" double false_position(double a, double b) noexcept
{
    if (!std::isfinite(a) || !std::isfinite(b) || a < 0.125 || a > 0.875 ||
        !((b >= -2.0 && b <= -0.125) || (b >= 1.125 && b <= 3.0))) return -1.0;
    double fa = function_value(a);
    double fb = function_value(b);
    if (!(fa < 0.0 && fb > 0.0)) return -1.0;
    double c = b;
    for (unsigned iteration = 0; iteration < 256; ++iteration) {
        c = b - fb * (b - a) / (fb - fa);
        const double fc = function_value(c);
        if (std::abs(fc) <= 1e-12) return c;
        if (fc < 0.0) {
            a = c;
            fa = fc;
        } else {
            b = c;
            fb = fc;
        }
    }
    return std::abs(fa) <= std::abs(fb) ? a : b;
}
