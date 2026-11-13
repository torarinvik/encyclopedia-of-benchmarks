#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;

std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t newton_reciprocal_fps(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > 64) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
    if (input[1] == 0) return -1;
    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::int64_t, 64> inverse{}, product{}, next{};
    inverse[0] = power(input[1], modulus - 2);
    for (std::size_t precision = 1; precision < n;) {
        const auto width = std::min(2 * precision, n);
        product.fill(0);
        for (std::size_t i = 0; i < width; ++i)
            for (std::size_t j = 0; j < precision && i + j < width; ++j)
                product[i + j] = (product[i + j] + input[i + 1] * inverse[j]) % modulus;
        product[0] = (2 + modulus - product[0]) % modulus;
        for (std::size_t i = 1; i < width; ++i) product[i] = (modulus - product[i]) % modulus;
        next.fill(0);
        for (std::size_t i = 0; i < precision; ++i)
            for (std::size_t j = 0; i + j < width; ++j)
                next[i + j] = (next[i + j] + inverse[i] * product[j]) % modulus;
        inverse = next;
        precision = width;
    }
    for (std::size_t i = 0; i < n; ++i) {
        auto bits = static_cast<std::uint64_t>(inverse[i]);
        for (std::size_t byte = 0; byte < 8; ++byte) {
            output[8 * i + byte] = static_cast<std::uint8_t>(bits & 255);
            bits >>= 8;
        }
    }
    return static_cast<std::int64_t>(bytes);
}
