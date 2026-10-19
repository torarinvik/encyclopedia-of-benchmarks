#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double mvt(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 1 || values[0] < 1 || values[0] > max_dimension) return invalid_result;
    const auto n = static_cast<std::size_t>(values[0]);
    double x1[max_dimension], x2[max_dimension], y1[max_dimension], y2[max_dimension], matrix[max_cells];
    for (std::size_t i = 0; i < n; ++i) {
        x1[i] = static_cast<double>(i % n) / static_cast<double>(n);
        x2[i] = static_cast<double>((i + 1) % n) / static_cast<double>(n);
        y1[i] = static_cast<double>((i + 3) % n) / static_cast<double>(n);
        y2[i] = static_cast<double>((i + 4) % n) / static_cast<double>(n);
        for (std::size_t j = 0; j < n; ++j)
            matrix[i * n + j] = static_cast<double>((i * j) % n) / static_cast<double>(n);
    }
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            x1[i] = x1[i] + matrix[i * n + j] * y1[j];
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            x2[i] = x2[i] + matrix[j * n + i] * y2[j];
    double checksum = 0;
    for (std::size_t i = 0; i < n; ++i) checksum += x1[i];
    for (std::size_t i = 0; i < n; ++i) checksum += x2[i];
    return checksum;
}
