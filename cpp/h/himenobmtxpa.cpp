#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t himenobmtxpa(const double *input, std::size_t length,
                                     double *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 4) return -1;
    for (std::size_t q = 0; q < 4; ++q)
        if (!std::isfinite(input[q]) || std::trunc(input[q]) != input[q]) return -1;
    if (input[0] < 2 || input[0] > 6 || input[1] < 2 || input[1] > 6 ||
        input[2] < 2 || input[2] > 6 || input[3] < 1 || input[3] > 4) return -1;
    const auto nx = static_cast<std::size_t>(input[0]);
    const auto ny = static_cast<std::size_t>(input[1]);
    const auto nz = static_cast<std::size_t>(input[2]);
    const auto iterations = static_cast<std::size_t>(input[3]);
    if (output == nullptr || capacity < 1) return -2;

    float p[216]{};
    float work[216]{};
    const float a3 = 1.0f / 6.0f, omega = 0.8f;
    const float denominator = static_cast<float>((nx - 1) * (nx - 1));
    for (std::size_t i = 0; i < nx; ++i)
        for (std::size_t j = 0; j < ny; ++j)
            for (std::size_t k = 0; k < nz; ++k) {
                const auto q = i * ny * nz + j * nz + k;
                p[q] = static_cast<float>(i * i) / denominator;
            }

    float gosa = 0.0f;
    for (std::size_t iteration = 0; iteration < iterations; ++iteration) {
        gosa = 0.0f;
        for (std::size_t i = 1; i + 1 < nx; ++i)
            for (std::size_t j = 1; j + 1 < ny; ++j)
                for (std::size_t k = 1; k + 1 < nz; ++k) {
                    const auto q = i * ny * nz + j * nz + k;
                    float s0 = p[q + ny * nz] + p[q + nz] + p[q + 1];
                    s0 = s0 + p[q - ny * nz] + p[q - nz] + p[q - 1];
                    const float ss = s0 * a3 - p[q];
                    gosa = gosa + ss * ss;
                    work[q] = p[q] + omega * ss;
                }
        for (std::size_t i = 1; i + 1 < nx; ++i)
            for (std::size_t j = 1; j + 1 < ny; ++j)
                for (std::size_t k = 1; k + 1 < nz; ++k) {
                    const auto q = i * ny * nz + j * nz + k;
                    p[q] = work[q];
                }
    }
    output[0] = static_cast<double>(gosa);
    return 1;
}
