#include <cmath>
#include <cstdint>

extern "C" std::int64_t fibonacci_number_golden_ration(std::int64_t input)
{
    if (input < 0 || input > 70) return -1;
    if (input <= 1) return input;

    const double sqrt5 = std::sqrt(5.0);
    const double phi = (1.0 + sqrt5) / 2.0;
    const double psi = (1.0 - sqrt5) / 2.0;
    const double result = (std::pow(phi, static_cast<double>(input))
                         - std::pow(psi, static_cast<double>(input))) / sqrt5;
    return static_cast<std::int64_t>(std::floor(result + 0.5));
}
