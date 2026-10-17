#include <cstddef>
#include <cstdint>

extern "C" double mean_bias_deviation_percent(const std::int64_t *input, std::size_t length) {
    constexpr double invalid = -1.0e300;
    if (input == nullptr || length < 1 || length > 131) return invalid;
    if (input[0] < 1 || input[0] > 64) return invalid;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * count) return invalid;
    std::int64_t difference_sum = 0, actual_sum = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t prediction = input[1 + index];
        const std::int64_t actual = input[1 + count + index];
        if (prediction < -1000 || prediction > 1000 || actual < -1000 || actual > 1000) return invalid;
        difference_sum += prediction - actual;
        actual_sum += actual;
    }
    if (actual_sum == 0) return invalid;
    const double numerator = static_cast<double>(difference_sum) / static_cast<double>(count);
    const double denominator = static_cast<double>(actual_sum) / static_cast<double>(count);
    return numerator / denominator * 100.0;
}
