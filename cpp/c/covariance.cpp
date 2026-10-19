#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double covariance(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 2 || values[0] < 2 || values[0] > max_dimension ||
        values[1] < 1 || values[1] > max_dimension) return invalid_result;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    const std::size_t m = static_cast<std::size_t>(values[1]);
    const double float_n = static_cast<double>(n);
    double data[max_cells], cov[max_cells], mean[max_dimension];
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < m; ++j)
            data[i * m + j] = (static_cast<double>(i) * static_cast<double>(j)) / static_cast<double>(m);
    for (std::size_t j = 0; j < m; ++j) {
        mean[j] = 0;
        for (std::size_t i = 0; i < n; ++i) mean[j] += data[i * m + j];
        mean[j] /= float_n;
    }
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < m; ++j) data[i * m + j] -= mean[j];
    for (std::size_t i = 0; i < m; ++i) {
        for (std::size_t j = i; j < m; ++j) {
            cov[i * m + j] = 0;
            for (std::size_t k = 0; k < n; ++k) cov[i * m + j] += data[k * m + i] * data[k * m + j];
            cov[i * m + j] /= float_n - 1.0;
            cov[j * m + i] = cov[i * m + j];
        }
    }
    double checksum = 0;
    for (std::size_t i = 0; i < m; ++i)
        for (std::size_t j = 0; j < m; ++j) checksum += cov[i * m + j];
    return checksum;
}
