// Cross-entropy loss with source-ordered intermediate terms and summation.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double cross_entropy_loss(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1) return -1.0e300;
    const std::int64_t count = values[0];
    if (count < 1 || count > 64 || length != 1 + 2 * static_cast<std::size_t>(count)) return -1.0e300;
    double terms[64];
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const std::int64_t actual_scaled = values[1 + i];
        const std::int64_t predicted_scaled = values[1 + static_cast<std::size_t>(count) + i];
        if (actual_scaled < 0 || actual_scaled > 1000000 ||
            predicted_scaled < 1 || predicted_scaled > 1000000) return -1.0e300;
        const double actual = static_cast<double>(actual_scaled) / 1000000.0;
        const double predicted = static_cast<double>(predicted_scaled) / 1000000.0;
        terms[i] = -actual * std::log(predicted);
    }
    double total = 0.0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) total += terms[i];
    return total;
}
