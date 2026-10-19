#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double gemm(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 3 || values[0] < 1 || values[0] > max_dimension ||
        values[1] < 1 || values[1] > max_dimension || values[2] < 1 || values[2] > max_dimension)
        return invalid_result;
    const std::size_t ni = static_cast<std::size_t>(values[0]);
    const std::size_t nj = static_cast<std::size_t>(values[1]);
    const std::size_t nk = static_cast<std::size_t>(values[2]);
    constexpr double alpha = 1.5, beta = 1.2;
    double c[max_cells], a[max_cells], b[max_cells];
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t j = 0; j < nj; ++j)
            c[i * nj + j] = static_cast<double>((i * j + 1) % ni) / static_cast<double>(ni);
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t k = 0; k < nk; ++k)
            a[i * nk + k] = static_cast<double>(i * (k + 1) % nk) / static_cast<double>(nk);
    for (std::size_t k = 0; k < nk; ++k)
        for (std::size_t j = 0; j < nj; ++j)
            b[k * nj + j] = static_cast<double>(k * (j + 2) % nj) / static_cast<double>(nj);
    for (std::size_t i = 0; i < ni; ++i) {
        for (std::size_t j = 0; j < nj; ++j) c[i * nj + j] *= beta;
        for (std::size_t k = 0; k < nk; ++k)
            for (std::size_t j = 0; j < nj; ++j)
                c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j];
    }
    double checksum = 0;
    for (std::size_t i = 0; i < ni; ++i)
        for (std::size_t j = 0; j < nj; ++j) checksum += c[i * nj + j];
    return checksum;
}
