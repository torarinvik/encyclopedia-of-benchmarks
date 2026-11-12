#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_coefficients = 8;
constexpr std::size_t max_n = 4;
constexpr std::size_t max_size = 16;
constexpr std::size_t max_input = 27;

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t polynomial_composite_set_power_series(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_coefficients) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_n)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    const auto n = static_cast<std::size_t>(input[1]);
    const std::size_t size = std::size_t{1} << n;
    if (length != 2 + count + size) return -1;
    for (std::size_t i = 0; i < count + size; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= modulus) return -1;

    const std::size_t bytes = 8 * size;
    if (output == nullptr || capacity < bytes) return -2;

    std::int64_t series[max_size]{};
    std::int64_t result[max_size]{};
    std::int64_t temporary[max_size]{};
    for (std::size_t mask = 0; mask < size; ++mask)
        series[mask] = input[2 + count + mask];

    for (std::size_t degree = count; degree > 0; --degree) {
        for (std::size_t mask = 0; mask < size; ++mask) {
            std::int64_t total = 0;
            auto subset = mask;
            for (;;) {
                total = (total + result[subset] * series[mask ^ subset]) % modulus;
                if (subset == 0) break;
                subset = (subset - 1) & mask;
            }
            temporary[mask] = total;
        }
        temporary[0] = (temporary[0] + input[1 + degree]) % modulus;
        for (std::size_t mask = 0; mask < size; ++mask)
            result[mask] = temporary[mask];
    }
    for (std::size_t mask = 0; mask < size; ++mask)
        store_le(output, 8 * mask, result[mask]);
    return static_cast<std::int64_t>(bytes);
}
