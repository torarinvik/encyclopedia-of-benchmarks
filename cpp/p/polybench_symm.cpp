#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double polybench_symm(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 2 || values[0] < 1 || values[0] > max_dimension ||
        values[1] < 1 || values[1] > max_dimension) return invalid_result;
    const auto m = static_cast<std::size_t>(values[0]), n = static_cast<std::size_t>(values[1]);
    double a[max_cells], b[max_cells], c[max_cells];
    const double alpha = 1.5, beta = 1.2;
    for (std::size_t i = 0; i < m; ++i)
        for (std::size_t j = 0; j < n; ++j) {
            c[i * n + j] = static_cast<double>((i + j) % 100) / static_cast<double>(m);
            b[i * n + j] = static_cast<double>((n + i - j) % 100) / static_cast<double>(m);
        }
    for (std::size_t i = 0; i < m; ++i)
        for (std::size_t j = 0; j < m; ++j)
            a[i * m + j] = j <= i ? static_cast<double>((i + j) % 100) / static_cast<double>(m) : -999.0;
    for (std::size_t i = 0; i < m; ++i)
        for (std::size_t j = 0; j < n; ++j) {
            double temp2 = 0.0;
            for (std::size_t k = 0; k < i; ++k) {
                c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k];
                temp2 = temp2 + b[k * n + j] * a[i * m + k];
            }
            c[i * n + j] = beta * c[i * n + j] + alpha * b[i * n + j] * a[i * m + i] + alpha * temp2;
        }
    double result = 0.0;
    for (std::size_t i = 0; i < m; ++i)
        for (std::size_t j = 0; j < n; ++j) result += c[i * n + j];
    return result;
}
