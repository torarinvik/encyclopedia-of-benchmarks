#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::int64_t half = 499122177;
using Series = std::array<std::int64_t, 64>;

Series multiply(const Series& left, const Series& right, std::size_t width) {
    Series result{};
    for (std::size_t i = 0; i < width; ++i)
        for (std::size_t j = 0; i + j < width; ++j)
            result[i + j] = (result[i + j] + left[i] * right[j]) % modulus;
    return result;
}
}

extern "C" std::int64_t newton_inverse_sqrt_fps(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > 64) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
    if (input[1] != 1) return -1;
    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    Series f{}, inverse{};
    for (std::size_t i = 0; i < n; ++i) f[i] = input[i + 1];
    inverse[0] = 1;
    for (std::size_t precision = 1; precision < n;) {
        const auto width = std::min(2 * precision, n);
        const auto square = multiply(inverse, inverse, width);
        const auto product = multiply(f, square, width);
        Series correction{};
        correction[0] = (3 + modulus - product[0]) * half % modulus;
        for (std::size_t i = 1; i < width; ++i)
            correction[i] = (modulus - product[i]) * half % modulus;
        inverse = multiply(inverse, correction, width);
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
