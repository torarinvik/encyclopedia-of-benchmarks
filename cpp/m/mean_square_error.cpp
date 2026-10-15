// Mean squared error over paired prediction and expected arrays.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 256; }

extern "C" double mean_square_error(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > 2 * max_length + 1) return -1.0e300;
    const auto count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_length) ||
        length != 2 * static_cast<std::size_t>(count_value) + 1) return -1.0e300;
    const auto count = static_cast<std::size_t>(count_value);
    double error_sum = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto predicted = values[index + 1];
        const auto expected = values[index + 1 + count];
        if (predicted < -1000000 || predicted > 1000000 || expected < -1000000 || expected > 1000000)
            return -1.0e300;
        const double difference = static_cast<double>(expected - predicted);
        error_sum += difference * difference;
    }
    return error_sum / static_cast<double>(count);
}
