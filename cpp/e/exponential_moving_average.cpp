#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
void put_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t exponential_moving_average(const std::int64_t *input, std::size_t length,
                                                      std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3) return -1;
    const auto window_value = input[0], count_value = input[1];
    if (window_value < 2 || window_value > 32 || count_value < 1 || count_value > 256) return -1;
    const auto window = static_cast<std::size_t>(window_value), count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return -1;
    for (std::size_t i = 0; i < count; ++i) if (input[2 + i] < -1000000 || input[2 + i] > 1000000) return -1;
    if (output == nullptr || capacity < count * 8) return -2;
    const double alpha = 2.0 / (1.0 + static_cast<double>(window));
    double average = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const double price = static_cast<double>(input[2 + i]);
        if (i == 0) average = price;
        else if (i <= window) average = (average + price) * 0.5;
        else average = (alpha * price) + ((1.0 - alpha) * average);
        put_f64_le(output, i * 8, average);
    }
    return static_cast<std::int64_t>(count * 8);
}
