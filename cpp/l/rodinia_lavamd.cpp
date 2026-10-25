/* Rodinia LavaMD bounded home-box force/potential kernel; see package LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kBias = INT64_C(1000000000000);
std::int64_t round_micro(double value) {
    const double scaled = value * 1'000'000.0;
    return scaled < 0.0 ? -static_cast<std::int64_t>(std::floor(-scaled + 0.5))
                        : static_cast<std::int64_t>(std::floor(scaled + 0.5));
}
}

extern "C" std::int64_t rodinia_lavamd(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 12 || length > 42 || input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4) return -1;
    const auto home_n = static_cast<std::size_t>(input[0]), neighbor_n = static_cast<std::size_t>(input[1]);
    if (length != 2 + 5 * (home_n + neighbor_n)) return -1;
    double particles[2][4][5]{};
    const std::size_t counts[2] = {home_n, neighbor_n};
    std::size_t cursor = 2;
    for (std::size_t box = 0; box < 2; ++box) for (std::size_t p = 0; p < counts[box]; ++p)
        for (std::size_t c = 0; c < 5; ++c) {
            const auto raw = input[cursor++];
            if (raw < 0 || raw > 1'000'000) return -1;
            particles[box][p][c] = static_cast<double>(raw) / 1'000'000.0;
        }
    double total = 0.0;
    for (std::size_t i = 0; i < home_n; ++i) {
        double fv = 0.0, fx = 0.0, fy = 0.0, fz = 0.0;
        const double *a = particles[0][i];
        for (std::size_t box = 0; box < 2; ++box) for (std::size_t j = 0; j < counts[box]; ++j) {
            const double *b = particles[box][j];
            const double dot = a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
            const double r2 = a[0] + b[0] - dot;
            const double vij = std::exp(-(0.5 * r2));
            const double fs = 2.0 * vij;
            const double dx = a[1] - b[1], dy = a[2] - b[2], dz = a[3] - b[3];
            fv += b[4] * vij; fx += b[4] * (fs * dx); fy += b[4] * (fs * dy); fz += b[4] * (fs * dz);
        }
        total += static_cast<double>(i + 1) * ((fv + fx) + fy + fz);
    }
    return kBias + round_micro(total);
}
