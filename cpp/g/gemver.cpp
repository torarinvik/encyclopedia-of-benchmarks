#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double gemver(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 1 || values[0] < 1 || values[0] > static_cast<std::int64_t>(max_dimension))
        return invalid_result;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    constexpr double alpha = 1.5, beta = 1.2;
    double a[max_cells] = {};
    double u1[max_dimension], v1[max_dimension], u2[max_dimension], v2[max_dimension];
    double w[max_dimension] = {}, x[max_dimension] = {}, y[max_dimension], z[max_dimension];
    for (std::size_t i = 0; i < n; ++i) {
        u1[i] = static_cast<double>(i);
        u2[i] = ((static_cast<double>(i) + 1.0) / static_cast<double>(n)) / 2.0;
        v1[i] = ((static_cast<double>(i) + 1.0) / static_cast<double>(n)) / 4.0;
        v2[i] = ((static_cast<double>(i) + 1.0) / static_cast<double>(n)) / 6.0;
        y[i] = ((static_cast<double>(i) + 1.0) / static_cast<double>(n)) / 8.0;
        z[i] = ((static_cast<double>(i) + 1.0) / static_cast<double>(n)) / 9.0;
        for (std::size_t j = 0; j < n; ++j)
            a[i * n + j] = static_cast<double>((i * j) % n) / static_cast<double>(n);
    }
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            a[i * n + j] = a[i * n + j] + u1[i] * v1[j] + u2[i] * v2[j];
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            x[i] = x[i] + beta * a[j * n + i] * y[j];
    for (std::size_t i = 0; i < n; ++i) x[i] = x[i] + z[i];
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            w[i] = w[i] + alpha * a[i * n + j] * x[j];
    double checksum = 0.0;
    for (std::size_t i = 0; i < n; ++i) checksum += w[i];
    return checksum;
}
