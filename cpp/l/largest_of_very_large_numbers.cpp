#include <cmath>
#include <cstddef>
#include <cstdint>

static constexpr std::int64_t MAX_VALUE = 1000000000000LL;

static double source_score(std::int64_t base, std::int64_t exponent) {
    if (base == 0) return 0.0;
    if (exponent == 0) return 1.0;
    return static_cast<double>(exponent) * std::log10(static_cast<double>(base));
}

static bool valid_comparison_domain(std::int64_t base_a, std::int64_t exponent_a,
                                   std::int64_t base_b, std::int64_t exponent_b) {
    return exponent_a == exponent_b ||
           (base_a == base_b &&
            (base_a == 0 || ((exponent_a == 0) == (exponent_b == 0))));
}

extern "C" std::int64_t largest_of_very_large_numbers(const std::int64_t* values,
                                                       std::size_t length) {
    if (values == nullptr || length != 4) return -2;
    for (std::size_t i = 0; i < 4; ++i) if (values[i] < 0 || values[i] > MAX_VALUE) return -2;
    if (!valid_comparison_domain(values[0], values[1], values[2], values[3])) return -2;
    const double a = source_score(values[0], values[1]);
    const double b = source_score(values[2], values[3]);
    return (a > b) - (a < b);
}
