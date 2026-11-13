#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t prime_modulus_inverse_table(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    constexpr std::int64_t modulus = 1000000007;
    if (input == nullptr || length < 1 || length > 34) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > 32) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 1) return -1;
    std::size_t maximum = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 1] < 1 || input[i + 1] > 256) return -1;
        const auto operand = static_cast<std::size_t>(input[i + 1]);
        if (operand > maximum) maximum = operand;
    }
    if (count == 0) return 0;
    const auto bytes = 4 * count;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::int64_t, 257> inverse{};
    inverse[1] = 1;
    for (std::size_t i = 2; i <= maximum; ++i) {
        const auto value = static_cast<std::int64_t>(i);
        inverse[i] = modulus - (modulus / value) * inverse[modulus % value] % modulus;
    }
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = static_cast<std::uint32_t>(inverse[input[i + 1]]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[4 * i + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
    }
    return static_cast<std::int64_t>(bytes);
}
