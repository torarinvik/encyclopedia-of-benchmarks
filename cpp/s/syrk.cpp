#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8;
constexpr std::size_t MAX_M = 16;

bool dimension_value(double value, std::size_t maximum)
{
    if (!(value >= 1.0 && value <= static_cast<double>(maximum))) return false;
    return static_cast<double>(static_cast<int>(value)) == value;
}
}

extern "C" std::int64_t syrk(const double *input, std::size_t length,
    double *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length != 2 || !dimension_value(input[0], MAX_N) ||
        !dimension_value(input[1], MAX_M)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t m = static_cast<std::size_t>(input[1]);
    constexpr double alpha = 1.5;
    constexpr double beta = 1.2;
    double a[MAX_N * MAX_M];
    double c[MAX_N * MAX_N];

    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t k = 0; k < m; ++k)
            a[i * m + k] = static_cast<double>((i * k + 1) % n) / static_cast<double>(n);
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            c[i * n + j] = static_cast<double>((i * j + 2) % m) / static_cast<double>(m);

    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j <= i; ++j) c[i * n + j] *= beta;
        for (std::size_t k = 0; k < m; ++k)
            for (std::size_t j = 0; j <= i; ++j)
                c[i * n + j] += alpha * a[i * m + k] * a[j * m + k];
    }

    const std::size_t required = n * n;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < required; ++index) output[index] = c[index];
    return static_cast<std::int64_t>(required);
}
