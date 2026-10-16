/* Nth derivative of x^power via truncated dual-number coefficients. */
#define INVALID_RESULT (-1e300)
constexpr int MAX_POWER = 8;

extern "C" double dual_number_automatic_differentiation(double position, double power, double order) noexcept
{
    if (!(position >= -1.0 && position <= 1.0) || !(power >= 0.0 && power <= MAX_POWER) ||
        !(order >= 0.0 && order <= MAX_POWER)) return INVALID_RESULT;
    const int exponent = static_cast<int>(power), derivative_order = static_cast<int>(order);
    if (power != static_cast<double>(exponent) || order != static_cast<double>(derivative_order) ||
        derivative_order > exponent) return INVALID_RESULT;

    double coefficients[MAX_POWER + 1] = {};
    coefficients[0] = 1.0;
    for (int step = 0; step < exponent; ++step) {
        double next[MAX_POWER + 1] = {};
        next[0] = coefficients[0] * position;
        for (int degree = 1; degree <= step + 1; ++degree)
            next[degree] = coefficients[degree] * position + coefficients[degree - 1];
        for (int degree = 0; degree <= MAX_POWER; ++degree) coefficients[degree] = next[degree];
    }
    double result = coefficients[derivative_order];
    for (int factor = 2; factor <= derivative_order; ++factor) result *= static_cast<double>(factor);
    return result;
}
