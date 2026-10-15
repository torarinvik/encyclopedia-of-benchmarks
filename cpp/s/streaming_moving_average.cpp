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

extern "C" std::int64_t streaming_moving_average(const std::int64_t *input, std::size_t length,
                                                   std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3) return -1;
    const auto window_value = input[0], count_value = input[1];
    if (window_value < 1 || window_value > 256 || count_value < 1 || count_value > 256) return -1;
    const auto window = static_cast<std::size_t>(window_value), count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return -1;
    for (std::size_t i = 0; i < count; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
    if (capacity < count * 8 || output == nullptr) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        const auto start = i + 1 > window ? i + 1 - window : 0;
        std::int64_t sum = 0;
        for (std::size_t j = start; j <= i; ++j) sum += input[2 + j];
        put_f64_le(output, i * 8, static_cast<double>(sum) / static_cast<double>(i + 1 - start));
    }
    return static_cast<std::int64_t>(count * 8);
}
