#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 16;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double two_mm(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 4) return invalid_result;
    for (std::size_t i = 0; i < 4; ++i)
        if (values[i] < 1 || values[i] > static_cast<std::int64_t>(max_dimension)) return invalid_result;
    const std::size_t ni = static_cast<std::size_t>(values[0]), nj = static_cast<std::size_t>(values[1]);
    const std::size_t nk = static_cast<std::size_t>(values[2]), nl = static_cast<std::size_t>(values[3]);
    constexpr double alpha = 1.5, beta = 1.2;
    double a[max_cells], b[max_cells], c[max_cells], d[max_cells], tmp[max_cells];
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t k = 0; k < nk; ++k) a[i * nk + k] = static_cast<double>((i * k + 1) % ni) / static_cast<double>(ni);
    for (std::size_t k = 0; k < nk; ++k)
        for (std::size_t j = 0; j < nj; ++j) b[k * nj + j] = static_cast<double>(k * (j + 1) % nj) / static_cast<double>(nj);
    for (std::size_t j = 0; j < nj; ++j)
        for (std::size_t l = 0; l < nl; ++l) c[j * nl + l] = static_cast<double>((j * (l + 3) + 1) % nl) / static_cast<double>(nl);
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t l = 0; l < nl; ++l) d[i * nl + l] = static_cast<double>(i * (l + 2) % nk) / static_cast<double>(nk);
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t j = 0; j < nj; ++j) {
            tmp[i * nj + j] = 0.0;
            for (std::size_t k = 0; k < nk; ++k) tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j];
        }
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t l = 0; l < nl; ++l) {
            d[i * nl + l] *= beta;
            for (std::size_t j = 0; j < nj; ++j) d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l];
        }
    double checksum = 0.0;
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t l = 0; l < nl; ++l) checksum += d[i * nl + l];
    return checksum;
}
