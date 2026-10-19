#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double polybench_cholesky(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 1 || values[0] < 1 || values[0] > max_dimension) return invalid_result;
    const auto n = static_cast<std::size_t>(values[0]);
    double a[max_cells], product[max_cells];
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j <= i; ++j)
            a[i * n + j] = static_cast<double>(-static_cast<std::int64_t>(j) % static_cast<std::int64_t>(n)) /
                           static_cast<double>(n) + 1.0;
        for (std::size_t j = i + 1; j < n; ++j) a[i * n + j] = 0.0;
        a[i * n + i] = 1.0;
    }
    for (std::size_t r = 0; r < n; ++r)
        for (std::size_t s = 0; s < n; ++s) product[r * n + s] = 0.0;
    for (std::size_t t = 0; t < n; ++t)
        for (std::size_t r = 0; r < n; ++r)
            for (std::size_t s = 0; s < n; ++s)
                product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
    for (std::size_t r = 0; r < n; ++r)
        for (std::size_t s = 0; s < n; ++s) a[r * n + s] = product[r * n + s];

    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < i; ++j) {
            for (std::size_t k = 0; k < j; ++k)
                a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k];
            a[i * n + j] = a[i * n + j] / a[j * n + j];
        }
        for (std::size_t k = 0; k < i; ++k)
            a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k];
        a[i * n + i] = std::sqrt(a[i * n + i]);
    }
    double result = 0.0;
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j <= i; ++j) result += a[i * n + j];
    return result;
}
