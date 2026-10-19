/* PolyBench/C trmm kernel, bounded cross-language port. See benchmarks/t/trmm/LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_m = 8, max_n = 8; }

extern "C" std::int64_t trmm(const double* input, std::size_t length,
                               double* output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 2 || !std::isfinite(input[0]) || !std::isfinite(input[1]) ||
        std::trunc(input[0]) != input[0] || std::trunc(input[1]) != input[1] ||
        input[0] < 1.0 || input[0] > max_m || input[1] < 1.0 || input[1] > max_n) return -1;
    const auto m = static_cast<std::size_t>(input[0]);
    const auto n = static_cast<std::size_t>(input[1]);
    const auto required = m * n;
    if (output == nullptr || capacity < required) return -2;
    double a[max_m][max_m]{};
    double b[max_m][max_n]{};
    constexpr double alpha = 1.5;
    for (std::size_t i = 0; i < m; ++i) {
        for (std::size_t j = 0; j < i; ++j) a[i][j] = static_cast<double>((i+j)%m) / static_cast<double>(m);
        a[i][i] = 1.0;
        for (std::size_t j = 0; j < n; ++j) b[i][j] = static_cast<double>((n+i-j)%n) / static_cast<double>(n);
    }
    for (std::size_t i = 0; i < m; ++i) for (std::size_t j = 0; j < n; ++j) {
        for (std::size_t k = i+1; k < m; ++k) b[i][j] += a[k][i] * b[k][j];
        b[i][j] = alpha * b[i][j];
    }
    double staged[max_m*max_n]{};
    for (std::size_t i = 0; i < m; ++i) for (std::size_t j = 0; j < n; ++j) staged[i*n+j] = b[i][j];
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}
