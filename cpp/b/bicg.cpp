#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double bicg(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 2 || values[0] < 1 || values[0] > max_dimension ||
        values[1] < 1 || values[1] > max_dimension) return invalid_result;
    const auto m = static_cast<std::size_t>(values[0]), n = static_cast<std::size_t>(values[1]);
    double matrix[max_cells], p[max_dimension], r[max_dimension], s[max_dimension], q[max_dimension];
    for (std::size_t i = 0; i < m; ++i) p[i] = static_cast<double>(i % m) / static_cast<double>(m);
    for (std::size_t i = 0; i < n; ++i) {
        r[i] = static_cast<double>(i % n) / static_cast<double>(n);
        for (std::size_t j = 0; j < m; ++j)
            matrix[i * m + j] = static_cast<double>((i * (j + 1)) % n) / static_cast<double>(n);
    }
    for (std::size_t i = 0; i < m; ++i) s[i] = 0;
    for (std::size_t i = 0; i < n; ++i) {
        q[i] = 0;
        for (std::size_t j = 0; j < m; ++j) {
            s[j] = s[j] + r[i] * matrix[i * m + j];
            q[i] = q[i] + matrix[i * m + j] * p[j];
        }
    }
    double checksum = 0;
    for (std::size_t j = 0; j < m; ++j) checksum += s[j];
    for (std::size_t i = 0; i < n; ++i) checksum += q[i];
    return checksum;
}
