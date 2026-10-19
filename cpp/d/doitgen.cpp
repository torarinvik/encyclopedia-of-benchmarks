#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 16;
constexpr std::size_t max_a_cells = max_dimension * max_dimension * max_dimension;
constexpr std::size_t max_c4_cells = max_dimension * max_dimension;
constexpr double invalid_result = -1e300;
}

extern "C" double doitgen(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length != 3 || values[0] < 1 || values[0] > max_dimension ||
        values[1] < 1 || values[1] > max_dimension || values[2] < 1 || values[2] > max_dimension)
        return invalid_result;
    const std::size_t nr = static_cast<std::size_t>(values[0]);
    const std::size_t nq = static_cast<std::size_t>(values[1]);
    const std::size_t np = static_cast<std::size_t>(values[2]);
    double a[max_a_cells], c4[max_c4_cells], sum[max_dimension];
    for (std::size_t r = 0; r < nr; ++r)
        for (std::size_t q = 0; q < nq; ++q)
            for (std::size_t p = 0; p < np; ++p)
                a[(r * nq + q) * np + p] = static_cast<double>((r * q + p) % np) / static_cast<double>(np);
    for (std::size_t i = 0; i < np; ++i)
        for (std::size_t j = 0; j < np; ++j)
            c4[i * np + j] = static_cast<double>(i * j % np) / static_cast<double>(np);
    for (std::size_t r = 0; r < nr; ++r)
        for (std::size_t q = 0; q < nq; ++q) {
            for (std::size_t p = 0; p < np; ++p) {
                sum[p] = 0;
                for (std::size_t s = 0; s < np; ++s)
                    sum[p] += a[(r * nq + q) * np + s] * c4[s * np + p];
            }
            for (std::size_t p = 0; p < np; ++p) a[(r * nq + q) * np + p] = sum[p];
        }
    double checksum = 0;
    for (std::size_t r = 0; r < nr; ++r)
        for (std::size_t q = 0; q < nq; ++q)
            for (std::size_t p = 0; p < np; ++p) checksum += a[(r * nq + q) * np + p];
    return checksum;
}
