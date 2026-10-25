// Bounded cell-centered restriction from the miniGMG multigrid operator.
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double doe_minigmg_restriction(const std::int64_t *values,
                                            std::size_t length) noexcept {
    if (values == nullptr || length < 11 || length > 515) return INVALID_RESULT;
    const auto nx_raw = values[0], ny_raw = values[1], nz_raw = values[2];
    if (nx_raw < 2 || nx_raw > 8 || nx_raw % 2 != 0 ||
        ny_raw < 2 || ny_raw > 8 || ny_raw % 2 != 0 ||
        nz_raw < 2 || nz_raw > 8 || nz_raw % 2 != 0) return INVALID_RESULT;

    const auto nx = static_cast<std::size_t>(nx_raw);
    const auto ny = static_cast<std::size_t>(ny_raw);
    const auto nz = static_cast<std::size_t>(nz_raw);
    const auto cells = nx * ny * nz;
    if (length != 3 + cells) return INVALID_RESULT;
    for (std::size_t i = 0; i < cells; ++i)
        if (values[3 + i] < -32768 || values[3 + i] > 32767) return INVALID_RESULT;

    const auto coarse_nx = nx / 2, coarse_ny = ny / 2, coarse_nz = nz / 2;
    const auto plane = nx * ny;
    double checksum = 0.0;
    std::size_t coarse_index = 0;
    for (std::size_t k = 0; k < coarse_nz; ++k) {
        for (std::size_t j = 0; j < coarse_ny; ++j) {
            for (std::size_t i = 0; i < coarse_nx; ++i) {
                const auto base = 3 + 2 * i + 2 * j * nx + 2 * k * plane;
                const double sum = static_cast<double>(values[base]) + static_cast<double>(values[base + 1]) +
                    static_cast<double>(values[base + nx]) + static_cast<double>(values[base + nx + 1]) +
                    static_cast<double>(values[base + plane]) + static_cast<double>(values[base + plane + 1]) +
                    static_cast<double>(values[base + plane + nx]) + static_cast<double>(values[base + plane + nx + 1]);
                const double restricted = sum * 0.125;
                const double weight = static_cast<double>(coarse_index + 1);
                checksum += weight * restricted * restricted;
                ++coarse_index;
            }
        }
    }
    return checksum;
}
