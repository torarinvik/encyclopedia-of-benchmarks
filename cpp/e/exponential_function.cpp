#include <cmath>

extern "C" double exponential_function(double power, double term_count) noexcept {
    if (!(power >= -10.0 && power <= 10.0 && term_count >= 0.0 && term_count <= 32.0)) return -1.0e300;
    const int n = static_cast<int>(term_count);
    if (static_cast<double>(n) != term_count) return -1.0e300;
    if (n == 0) return 1.0;

    double output = 0.0;
    double factorial = 1.0;
    for (int i = 0; i < n; ++i) {
        output += std::pow(power, static_cast<double>(i)) / factorial;
        factorial *= static_cast<double>(i + 1);
    }
    return output;
}
