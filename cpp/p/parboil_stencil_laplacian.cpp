/* Clean-room bounded Parboil seven-point Laplacian profile. */
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t parboil_stencil_laplacian(const double* input, std::size_t length,
                                                  double* output, std::size_t capacity) noexcept {
    if (!input || length < 4 || length > 129) return -1;
    for (std::size_t h = 0; h < 4; ++h)
        if (!std::isfinite(input[h]) || std::trunc(input[h]) != input[h]) return -1;
    if (input[0] < 3 || input[0] > 5 || input[1] < 3 || input[1] > 5 ||
        input[2] < 3 || input[2] > 5 || input[3] < 1 || input[3] > 4) return -1;
    const auto nx = static_cast<std::size_t>(input[0]);
    const auto ny = static_cast<std::size_t>(input[1]);
    const auto nz = static_cast<std::size_t>(input[2]);
    const auto steps = static_cast<std::size_t>(input[3]);
    const auto cells = nx * ny * nz;
    if (length != 4 + cells) return -1;
    for (std::size_t q = 0; q < cells; ++q)
        if (!std::isfinite(input[4 + q]) || input[4 + q] < -8.0 || input[4 + q] > 8.0) return -1;
    if (!output || capacity < cells) return -2;

    float a[125]{}, b[125]{};
    double staged[125]{};
    for (std::size_t q = 0; q < cells; ++q) a[q] = b[q] = static_cast<float>(input[4 + q]);
    const float c0 = 1.0f / 6.0f;
    const float c1 = (1.0f / 6.0f) / 6.0f;
    for (std::size_t step = 0; step < steps; ++step) {
        for (std::size_t i = 1; i + 1 < nx; ++i)
            for (std::size_t j = 1; j + 1 < ny; ++j)
                for (std::size_t k = 1; k + 1 < nz; ++k) {
                    const auto q = i + nx * (j + ny * k);
                    float sum = a[q + nx * ny] + a[q - nx * ny];
                    sum = sum + a[q + nx]; sum = sum + a[q - nx];
                    sum = sum + a[q + 1]; sum = sum + a[q - 1];
                    const float neighbor_term = sum * c1;
                    const float center_term = a[q] * c0;
                    b[q] = neighbor_term - center_term;
                }
        for (std::size_t q = 0; q < cells; ++q) { const float temp = a[q]; a[q] = b[q]; b[q] = temp; }
    }
    for (std::size_t q = 0; q < cells; ++q) staged[q] = static_cast<double>(a[q]);
    for (std::size_t q = 0; q < cells; ++q) output[q] = staged[q];
    return static_cast<std::int64_t>(cells);
}
