#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_s275_column_conditional_axpy_recurrence(const double *input,
    std::size_t length, double *output, std::size_t capacity) {
    constexpr std::size_t max_n = 8;
    if (input == nullptr || length < 2 || length > 193) return -1;
    const double rn = input[0];
    if (!std::isfinite(rn) || std::trunc(rn) != rn || rn < 1 || rn > max_n) return -1;
    const std::size_t n = static_cast<std::size_t>(rn), cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (!std::isfinite(input[i]) || std::trunc(input[i]) != input[i] || std::abs(input[i]) > 16) return -1;
    if (output == nullptr || capacity < cells) return -2;
    double a[max_n * max_n]{};
    for (std::size_t i = 0; i < cells; ++i) a[i] = input[1 + i];
    const std::size_t bs = 1 + cells, cs = 1 + 2 * cells;
    for (std::size_t col = 0; col < n; ++col) {
        if (a[col] > 0.0) {
            for (std::size_t row = 1; row < n; ++row) {
                const std::size_t index = row * n + col;
                a[index] = a[index - n] + input[bs + index] * input[cs + index];
            }
        }
    }
    for (std::size_t i = 0; i < cells; ++i) output[i] = a[i];
    return static_cast<std::int64_t>(cells);
}
