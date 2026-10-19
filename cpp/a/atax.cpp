#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double atax(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 2 || values[0] < 1 || values[0] > max_dimension ||
        values[1] < 1 || values[1] > max_dimension) return invalid_result;
    const auto m = static_cast<std::size_t>(values[0]), n = static_cast<std::size_t>(values[1]);
    double matrix[max_cells], x[max_dimension], y[max_dimension], temporary[max_dimension];
    const double fn = static_cast<double>(n);
    for (std::size_t i = 0; i < n; ++i) x[i] = 1.0 + static_cast<double>(i) / fn;
    for (std::size_t i = 0; i < m; ++i)
        for (std::size_t j = 0; j < n; ++j)
            matrix[i * n + j] = static_cast<double>((i + j) % n) / static_cast<double>(5 * m);
    for (std::size_t i = 0; i < n; ++i) y[i] = 0.0;
    for (std::size_t i = 0; i < m; ++i) {
        temporary[i] = 0.0;
        for (std::size_t j = 0; j < n; ++j)
            temporary[i] = temporary[i] + matrix[i * n + j] * x[j];
        for (std::size_t j = 0; j < n; ++j)
            y[j] = y[j] + matrix[i * n + j] * temporary[i];
    }
    double checksum = 0.0;
    for (std::size_t j = 0; j < n; ++j) checksum += y[j];
    return checksum;
}
