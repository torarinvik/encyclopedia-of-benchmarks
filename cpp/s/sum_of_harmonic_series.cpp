#include <cmath>
#include <cstdint>
namespace { constexpr double INVALID_RESULT = -1.0e300; }
extern "C" double sum_of_harmonic_series(double first_term, double common_difference, double number_of_terms) noexcept {
    if (!std::isfinite(first_term) || !std::isfinite(common_difference) || !std::isfinite(number_of_terms) ||
        first_term <= 0.0 || first_term > 1000.0 || common_difference < 0.0 || common_difference > 1000.0 ||
        number_of_terms < 1.0 || number_of_terms > 256.0 || std::floor(number_of_terms) != number_of_terms) return INVALID_RESULT;
    const std::int32_t count = static_cast<std::int32_t>(number_of_terms);
    double arithmetic_term = 1.0 / first_term;
    double sum = 0.0;
    for (std::int32_t index = 0; index < count; ++index) {
        sum += 1.0 / arithmetic_term;
        if (index + 1 < count) arithmetic_term += common_difference;
    }
    return sum;
}
