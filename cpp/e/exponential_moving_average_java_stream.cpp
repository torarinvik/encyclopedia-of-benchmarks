#include <cstddef>
#include <cstdint>
#include <cstring>

static void put_f64_le(double value, std::uint8_t *output, std::size_t offset) {
    std::uint64_t bits; std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
static void put_i64_le(std::int64_t value, std::uint8_t *output, std::size_t offset) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t exponential_moving_average_java_stream(const std::int64_t *input, std::size_t length,
                                                                std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 2 || input[1] < 0 || input[1] > 256 || length != 2 + static_cast<std::size_t>(input[1])) return -1;
    if (input[0] < -1000000 || input[0] > 1000000) return -1;
    double mean = static_cast<double>(input[0]), variance = 0.0;
    for (std::size_t index = 0; index < static_cast<std::size_t>(input[1]); ++index) {
        if (input[index + 2] < -1000000 || input[index + 2] > 1000000) return -1;
        const double value = static_cast<double>(input[index + 2]);
        const double deviation = value - mean;
        mean += 0.25 * deviation;
        variance = 0.75 * (variance + 0.25 * deviation * deviation);
    }
    if (!output || capacity < 24) return -2;
    put_f64_le(mean, output, 0); put_f64_le(variance, output, 8); put_i64_le(input[1], output, 16);
    return 24;
}
