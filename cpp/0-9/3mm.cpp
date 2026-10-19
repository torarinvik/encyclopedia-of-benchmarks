#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 16;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double three_mm(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 5) return invalid_result;
    for (std::size_t i = 0; i < 5; ++i)
        if (values[i] < 1 || values[i] > static_cast<std::int64_t>(max_dimension)) return invalid_result;
    const std::size_t ni = static_cast<std::size_t>(values[0]), nj = static_cast<std::size_t>(values[1]);
    const std::size_t nk = static_cast<std::size_t>(values[2]), nl = static_cast<std::size_t>(values[3]);
    const std::size_t nm = static_cast<std::size_t>(values[4]);
    double a[max_cells], b[max_cells], c[max_cells], d[max_cells], e[max_cells], f[max_cells], g[max_cells];
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t k = 0; k < nk; ++k) a[i * nk + k] = static_cast<double>((i * k + 1) % ni) / static_cast<double>(5 * ni);
    for (std::size_t k = 0; k < nk; ++k)
        for (std::size_t j = 0; j < nj; ++j) b[k * nj + j] = static_cast<double>((k * (j + 1) + 2) % nj) / static_cast<double>(5 * nj);
    for (std::size_t i = 0; i < nj; ++i)
        for (std::size_t j = 0; j < nm; ++j) c[i * nm + j] = static_cast<double>(i * (j + 3) % nl) / static_cast<double>(5 * nl);
    for (std::size_t i = 0; i < nm; ++i)
        for (std::size_t j = 0; j < nl; ++j) d[i * nl + j] = static_cast<double>((i * (j + 2) + 2) % nk) / static_cast<double>(5 * nk);
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t j = 0; j < nj; ++j) {
            e[i * nj + j] = 0.0;
            for (std::size_t k = 0; k < nk; ++k) e[i * nj + j] += a[i * nk + k] * b[k * nj + j];
        }
    for (std::size_t i = 0; i < nj; ++i)
        for (std::size_t j = 0; j < nl; ++j) {
            f[i * nl + j] = 0.0;
            for (std::size_t k = 0; k < nm; ++k) f[i * nl + j] += c[i * nm + k] * d[k * nl + j];
        }
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t j = 0; j < nl; ++j) {
            g[i * nl + j] = 0.0;
            for (std::size_t k = 0; k < nj; ++k) g[i * nl + j] += e[i * nj + k] * f[k * nl + j];
        }
    double checksum = 0.0;
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t j = 0; j < nl; ++j) checksum += g[i * nl + j];
    return checksum;
}
