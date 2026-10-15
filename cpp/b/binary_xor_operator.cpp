#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_xor_operator(const std::int64_t* input, std::size_t length,
                                             std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length != 2 || input[0] < 0 || input[0] > 2147483647 || input[1] < 0 || input[1] > 2147483647) return -1;
    const auto a = static_cast<std::uint64_t>(input[0]);
    const auto b = static_cast<std::uint64_t>(input[1]);
    auto largest = a > b ? a : b;
    std::size_t width = 1;
    while (largest > 1) { ++width; largest >>= 1; }
    const auto output_length = width + 2;
    if (capacity < output_length || !output) return -2;
    const auto result = a ^ b;
    output[0] = '0'; output[1] = 'b';
    for (std::size_t i = 0; i < width; ++i) {
        const auto bit = width - 1 - i;
        output[2 + i] = static_cast<std::uint8_t>(((result >> bit) & 1) ? '1' : '0');
    }
    return static_cast<std::int64_t>(output_length);
}
