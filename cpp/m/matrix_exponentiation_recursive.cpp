#include <cstddef>
#include <cstdint>

namespace {
struct Matrix2 { std::int64_t v[4]; };
void store_i64_le(std::int64_t value, std::uint8_t *out, std::size_t offset) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
Matrix2 multiply(Matrix2 a, Matrix2 b) {
    Matrix2 c{{0, 0, 0, 0}};
    for (std::size_t r = 0; r < 2; ++r) for (std::size_t col = 0; col < 2; ++col)
        for (std::size_t k = 0; k < 2; ++k) c.v[r * 2 + col] += a.v[r * 2 + k] * b.v[k * 2 + col];
    return c;
}
Matrix2 power(Matrix2 a, std::int64_t e) {
    if (e == 0) return Matrix2{{1, 0, 0, 1}};
    if (e & 1) return multiply(power(a, e - 1), a);
    Matrix2 half = power(a, e / 2);
    return multiply(half, half);
}
}
extern "C" std::int64_t matrix_exponentiation_recursive(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length != 5 || input[0] < 0 || input[0] > 30) return -2;
    for (std::size_t i = 1; i < 5; ++i) if (input[i] < -1 || input[i] > 1) return -2;
    if (!output || capacity < 32) return -3;
    Matrix2 a{{input[1], input[2], input[3], input[4]}};
    Matrix2 result = power(a, input[0]);
    for (std::size_t i = 0; i < 4; ++i) store_i64_le(result.v[i], output, i * 8);
    return 4;
}
