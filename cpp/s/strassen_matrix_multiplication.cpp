/* Seven-product Strassen multiplication for bounded square matrices. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8;
constexpr std::size_t MAX_INPUT_LENGTH = 129;

void strassen_multiply(const std::int64_t *a, const std::int64_t *b,
                       std::int64_t *c, std::size_t n) noexcept
{
    if (n == 1) { c[0] = a[0] * b[0]; return; }
    const std::size_t half = n / 2;
    std::int64_t x[16]{}, y[16]{};
    std::int64_t m1[16]{}, m2[16]{}, m3[16]{}, m4[16]{}, m5[16]{}, m6[16]{}, m7[16]{};
    for (std::size_t r = 0; r < half; ++r) for (std::size_t col = 0; col < half; ++col) {
        const std::size_t i = r * half + col, q = r * n + col;
        x[i] = a[q] + a[(r + half) * n + col + half];
        y[i] = b[q] + b[(r + half) * n + col + half];
    }
    strassen_multiply(x, y, m1, half);
    for (std::size_t r = 0; r < half; ++r) for (std::size_t col = 0; col < half; ++col) {
        const std::size_t i = r * half + col;
        x[i] = a[(r + half) * n + col] + a[(r + half) * n + col + half]; y[i] = b[r * n + col];
    }
    strassen_multiply(x, y, m2, half);
    for (std::size_t r = 0; r < half; ++r) for (std::size_t col = 0; col < half; ++col) {
        const std::size_t i = r * half + col;
        x[i] = a[r * n + col]; y[i] = b[r * n + col + half] - b[(r + half) * n + col + half];
    }
    strassen_multiply(x, y, m3, half);
    for (std::size_t r = 0; r < half; ++r) for (std::size_t col = 0; col < half; ++col) {
        const std::size_t i = r * half + col;
        x[i] = a[(r + half) * n + col + half]; y[i] = b[(r + half) * n + col] - b[r * n + col];
    }
    strassen_multiply(x, y, m4, half);
    for (std::size_t r = 0; r < half; ++r) for (std::size_t col = 0; col < half; ++col) {
        const std::size_t i = r * half + col;
        x[i] = a[r * n + col] + a[r * n + col + half]; y[i] = b[(r + half) * n + col + half];
    }
    strassen_multiply(x, y, m5, half);
    for (std::size_t r = 0; r < half; ++r) for (std::size_t col = 0; col < half; ++col) {
        const std::size_t i = r * half + col;
        x[i] = a[(r + half) * n + col] - a[r * n + col]; y[i] = b[r * n + col] + b[r * n + col + half];
    }
    strassen_multiply(x, y, m6, half);
    for (std::size_t r = 0; r < half; ++r) for (std::size_t col = 0; col < half; ++col) {
        const std::size_t i = r * half + col;
        x[i] = a[r * n + col + half] - a[(r + half) * n + col + half];
        y[i] = b[(r + half) * n + col] + b[(r + half) * n + col + half];
    }
    strassen_multiply(x, y, m7, half);
    for (std::size_t r = 0; r < half; ++r) for (std::size_t col = 0; col < half; ++col) {
        const std::size_t i = r * half + col;
        c[r * n + col] = m1[i] + m4[i] - m5[i] + m7[i];
        c[r * n + col + half] = m3[i] + m5[i];
        c[(r + half) * n + col] = m2[i] + m4[i];
        c[(r + half) * n + col + half] = m1[i] - m2[i] + m3[i] + m6[i];
    }
}
}

extern "C" std::int64_t strassen_matrix_multiplication(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t n_value = input[0];
    if (n_value != 1 && n_value != 2 && n_value != 4 && n_value != 8) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value), cells = n * n;
    if (length != 1 + 2 * cells) return -1;
    for (std::size_t i = 0; i < 2 * cells; ++i) if (input[1 + i] < -2 || input[1 + i] > 2) return -1;
    const std::size_t output_bytes = 8 * cells;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::int64_t result[MAX_N * MAX_N]{};
    strassen_multiply(input + 1, input + 1 + cells, result, n);
    for (std::size_t i = 0; i < cells; ++i) {
        std::uint64_t bits = static_cast<std::uint64_t>(result[i]);
        for (std::size_t byte = 0; byte < 8; ++byte) {
            output[i * 8 + byte] = static_cast<std::uint8_t>(bits & 255);
            bits >>= 8;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
