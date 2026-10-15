// Mean absolute error over paired prediction and actual arrays.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 256; }

extern "C" double mean_absolute_error_loss(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > 2 * max_length + 1) return -1.0e300;
    const auto count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_length) ||
        length != 2 * static_cast<std::size_t>(count_value) + 1) return -1.0e300;
    const auto count = static_cast<std::size_t>(count_value);
    double absolute_sum = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto predicted = values[index + 1];
        const auto actual = values[index + 1 + count];
        if (predicted < -1000000 || predicted > 1000000 || actual < -1000000 || actual > 1000000)
            return -1.0e300;
        double difference = static_cast<double>(predicted - actual);
        if (difference < 0.0) difference = -difference;
        absolute_sum += difference;
    }
    return absolute_sum / static_cast<double>(count);
}
