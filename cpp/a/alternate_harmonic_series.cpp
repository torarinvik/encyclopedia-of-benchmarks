// Check alternating signs and a constant step in reciprocal magnitudes.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_count = 1000; }

extern "C" std::int64_t alternate_harmonic_series(const std::int64_t *values,
    std::size_t length) noexcept {
    if (values == nullptr || length < 1) return -1;
    const auto count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_count)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return -1;

    for (std::size_t index = 0; index < count; ++index) {
        const auto numerator = values[1 + 2 * index];
        const auto denominator = values[2 + 2 * index];
        if (numerator < -1000 || numerator > 1000 || numerator == 0 ||
            denominator < 1 || denominator > 1000) return -1;
    }

    std::int64_t previous_difference_numerator = 0;
    std::int64_t previous_difference_denominator = 1;
    std::int64_t previous_magnitude = 0;
    std::int64_t previous_denominator = 0;

    for (std::size_t index = 0; index < count; ++index) {
        const auto numerator = values[1 + 2 * index];
        const auto denominator = values[2 + 2 * index];
        const auto magnitude = numerator < 0 ? -numerator : numerator;

        if (index > 0) {
            if (index > 1 &&
                (numerator < 0) == (values[1 + 2 * (index - 1)] < 0)) return 0;
            const auto difference_numerator =
                denominator * previous_magnitude - previous_denominator * magnitude;
            const auto difference_denominator = magnitude * previous_magnitude;
            if (index > 1 &&
                difference_numerator * previous_difference_denominator !=
                    previous_difference_numerator * difference_denominator) return 0;
            previous_difference_numerator = difference_numerator;
            previous_difference_denominator = difference_denominator;
        }
        previous_magnitude = magnitude;
        previous_denominator = denominator;
    }
    return 1;
}
