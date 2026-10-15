// Check rationals against the canonical finite alternating harmonic terms.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_count = 1000; }

extern "C" std::int64_t alternating_harmonic_series(const std::int64_t *values,
    std::size_t length) noexcept {
    if (values == nullptr || length < 1) return -1;
    const auto count_value = values[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_count)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return -1;
    if (count == 0) return 0;

    for (std::size_t index = 0; index < count; ++index) {
        const auto numerator = values[1 + 2 * index];
        const auto denominator = values[2 + 2 * index];
        if (numerator < -1000 || numerator > 1000 ||
            denominator < 1 || denominator > 1000) return -1;
    }

    for (std::size_t index = 0; index < count; ++index) {
        const auto numerator = values[1 + 2 * index];
        const auto denominator = values[2 + 2 * index];
        const auto term_index = static_cast<std::int64_t>(index) + 1;
        const std::int64_t sign = index % 2 == 0 ? 1 : -1;
        auto error = numerator * term_index - sign * denominator;
        if (error < 0) error = -error;
        if (error * 1000000000LL > denominator * term_index) return 0;
    }
    return 1;
}
