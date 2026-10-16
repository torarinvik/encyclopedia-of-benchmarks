#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_SAMPLE_COUNT = 128;

void put_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t data_normalization_standardization(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (values == nullptr || length < 4 || length > MAX_SAMPLE_COUNT + 2) return -1;
    const std::int64_t mode = values[0];
    const std::int64_t count_arg = values[1];
    if ((mode != 0 && mode != 1) || count_arg < 2 || count_arg > MAX_SAMPLE_COUNT ||
        length != static_cast<std::size_t>(count_arg) + 2) return -1;
    const std::size_t count = static_cast<std::size_t>(count_arg);
    std::int64_t minimum = values[2];
    std::int64_t maximum = values[2];
    double sum = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = values[index + 2];
        if (value < -100000 || value > 100000) return -1;
        if (value < minimum) minimum = value;
        if (value > maximum) maximum = value;
        sum += static_cast<double>(value);
    }
    if (minimum == maximum) return -1;
    const std::size_t output_bytes = count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    if (mode == 0) {
        const double span = static_cast<double>(maximum - minimum);
        for (std::size_t index = 0; index < count; ++index) {
            const double normalized = (static_cast<double>(values[index + 2]) -
                                       static_cast<double>(minimum)) / span;
            put_f64_le(output, index * 8, normalized);
        }
    } else {
        const double mean = sum / static_cast<double>(count);
        double squared_deviations = 0.0;
        for (std::size_t index = 0; index < count; ++index) {
            const double deviation = static_cast<double>(values[index + 2]) - mean;
            squared_deviations += deviation * deviation;
        }
        const double sample_deviation = std::sqrt(squared_deviations / static_cast<double>(count - 1));
        for (std::size_t index = 0; index < count; ++index) {
            const double standardized = (static_cast<double>(values[index + 2]) - mean) / sample_deviation;
            put_f64_le(output, index * 8, standardized);
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
