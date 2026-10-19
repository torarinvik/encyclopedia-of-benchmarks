#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8;
constexpr int max_m = 16;

bool dimension_value(double value, int maximum) noexcept
{
    return value >= 1.0 && value <= static_cast<double>(maximum)
        && static_cast<double>(static_cast<int>(value)) == value;
}
}

extern "C" std::int64_t syr2k(const double *input, std::size_t length,
                               double *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length != 2 || !dimension_value(input[0], max_n)
        || !dimension_value(input[1], max_m)) return -1;
    const int n = static_cast<int>(input[0]);
    const int m = static_cast<int>(input[1]);
    constexpr double alpha = 1.5;
    constexpr double beta = 1.2;
    double a[max_n * max_m]{};
    double b[max_n * max_m]{};
    double c[max_n * max_n]{};

    for (int i = 0; i < n; ++i)
        for (int j = 0; j < m; ++j) {
            a[i * m + j] = static_cast<double>((i * j + 1) % n) / n;
            b[i * m + j] = static_cast<double>((i * j + 2) % m) / m;
        }
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            c[i * n + j] = static_cast<double>((i * j + 3) % n) / m;

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j <= i; ++j) c[i * n + j] *= beta;
        for (int k = 0; k < m; ++k)
            for (int j = 0; j <= i; ++j)
                c[i * n + j] += a[j * m + k] * alpha * b[i * m + k]
                              + b[j * m + k] * alpha * a[i * m + k];
    }

    const std::size_t required = static_cast<std::size_t>(n * n);
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < required; ++index) output[index] = c[index];
    return static_cast<std::int64_t>(required);
}
