#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
using Series = std::array<std::int64_t, 16>;
constexpr std::int64_t modulus = 998244353;

std::int64_t power(std::int64_t value, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent) {
        if (exponent & 1) result = result * value % modulus;
        value = value * value % modulus;
        exponent >>= 1;
    }
    return result;
}

Series multiply(const Series& left, const Series& right, std::size_t width) {
    Series result{};
    for (std::size_t i = 0; i < width; ++i)
        for (std::size_t j = 0; i + j < width; ++j)
            result[i + j] = (result[i + j] + left[i] * right[j]) % modulus;
    return result;
}

Series compose(const Series& outer, const Series& inner, std::size_t width) {
    Series result{};
    for (std::size_t i = width; i-- > 0;) {
        result = multiply(result, inner, width);
        result[0] = (result[0] + outer[i]) % modulus;
    }
    return result;
}
}

extern "C" std::int64_t newton_compositional_inverse_fps(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 18) return -1;
    if (input[0] < 2 || input[0] > 16) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
    if (input[1] != 0 || input[2] == 0) return -1;
    const auto bytes = n * 8;
    if (output == nullptr || capacity < bytes) return -2;
    Series f{}, derivative{}, inverse{};
    for (std::size_t i = 0; i < n; ++i) f[i] = input[i + 1];
    for (std::size_t i = 1; i < n; ++i)
        derivative[i - 1] = static_cast<std::int64_t>(i) * f[i] % modulus;
    const auto linear_inverse = power(f[1], modulus - 2);
    inverse[1] = linear_inverse;
    for (std::size_t precision = 2; precision < n;) {
        const auto width = std::min(2 * precision, n);
        auto residual = compose(f, inverse, width);
        residual[1] = (residual[1] + modulus - 1) % modulus;
        const auto slope = compose(derivative, inverse, width);
        Series reciprocal{};
        reciprocal[0] = linear_inverse;
        for (std::size_t i = 1; i < width; ++i) {
            std::int64_t sum = 0;
            for (std::size_t j = 1; j <= i; ++j)
                sum = (sum + slope[j] * reciprocal[i - j]) % modulus;
            reciprocal[i] = (modulus - sum) * linear_inverse % modulus;
        }
        const auto correction = multiply(residual, reciprocal, width);
        for (std::size_t i = 0; i < width; ++i)
            inverse[i] = (inverse[i] + modulus - correction[i]) % modulus;
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
