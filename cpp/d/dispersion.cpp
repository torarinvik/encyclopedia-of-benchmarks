#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_INPUT = 128;
constexpr std::int64_t OUTPUT_BYTES = 16;

void put_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t i = 0; i < 8; ++i) output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t dispersion(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length == 0 || length > MAX_INPUT) return -1;
    for (std::size_t i = 0; i < length; ++i) if (values[i] < -10000 || values[i] > 10000) return -1;
    if (output == nullptr || capacity < OUTPUT_BYTES) return -2;
    double sum = 0.0;
    for (std::size_t i = 0; i < length; ++i) sum += static_cast<double>(values[i]);
    const double mean = sum / static_cast<double>(length);
    double squared_deviations = 0.0;
    for (std::size_t i = 0; i < length; ++i) {
        const double deviation = static_cast<double>(values[i]) - mean;
        squared_deviations += deviation * deviation;
    }
    const double variance = squared_deviations / static_cast<double>(length);
    const double standard_deviation = std::sqrt(variance);
    put_f64_le(output, 0, variance);
    put_f64_le(output, 8, standard_deviation);
    return OUTPUT_BYTES;
}
