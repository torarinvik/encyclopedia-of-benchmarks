// Clean-room bounded residual profile; see package README and RIGHTS.md.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t asci_purple_smg2000_residual(
    const double* input, std::size_t length, double* output, std::size_t capacity) noexcept {
    if (!input || length < 19 || length > 253) return -1;
    for (std::size_t q = 0; q < 3; ++q)
        if (!std::isfinite(input[q]) || std::trunc(input[q]) != input[q] || input[q] < 2 || input[q] > 5) return -1;
    const auto nx = std::size_t(input[0]), ny = std::size_t(input[1]), nz = std::size_t(input[2]);
    const auto cells = nx * ny * nz;
    if (length != 3 + 2 * cells) return -1;
    for (std::size_t q = 3; q < length; ++q)
        if (!std::isfinite(input[q]) || std::trunc(input[q]) != input[q] || input[q] < -1000 || input[q] > 1000) return -1;
    if (!output || capacity < cells) return -2;
    const auto si = ny * nz, sj = nz;
    for (std::size_t i = 0; i < nx; ++i) for (std::size_t j = 0; j < ny; ++j) for (std::size_t k = 0; k < nz; ++k) {
        const auto q = i * si + j * sj + k;
        const auto x = std::int64_t(input[3 + q]);
        std::int64_t ax = 222 * x;
        if (i > 0) ax -= std::int64_t(input[3 + q - si]);
        if (i + 1 < nx) ax -= std::int64_t(input[3 + q + si]);
        if (j > 0) ax -= 10 * std::int64_t(input[3 + q - sj]);
        if (j + 1 < ny) ax -= 10 * std::int64_t(input[3 + q + sj]);
        if (k > 0) ax -= 100 * std::int64_t(input[3 + q - 1]);
        if (k + 1 < nz) ax -= 100 * std::int64_t(input[3 + q + 1]);
        const auto b = std::int64_t(input[3 + cells + q]);
        output[q] = double(10 * b - ax) / 10.0;
    }
    return std::int64_t(cells);
}
