#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_dimension = 32;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr std::int64_t max_tsteps = 20;

void write_f64_le(std::uint8_t *output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t polybench_adi(const std::int64_t *values, std::size_t length,
                                       std::uint8_t *output,
                                       std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 2 || values[0] < 1 || values[0] > max_dimension ||
        values[1] < 1 || values[1] > max_tsteps) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    const auto tsteps = static_cast<std::size_t>(values[1]);
    const auto cells = n * n;
    const auto output_bytes = cells * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    double u[max_cells]{}, v[max_cells]{}, p[max_cells]{}, q[max_cells]{};
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            u[i * n + j] = static_cast<double>(i + n - j) / static_cast<double>(n);

    const double dx = 1.0 / static_cast<double>(n);
    const double dy = 1.0 / static_cast<double>(n);
    const double dt = 1.0 / static_cast<double>(tsteps);
    const double b1 = 2.0, b2 = 1.0;
    const double mul1 = b1 * dt / (dx * dx);
    const double mul2 = b2 * dt / (dy * dy);
    const double a = -mul1 / 2.0;
    const double b = 1.0 + mul1;
    const double c = a;
    const double d = -mul2 / 2.0;
    const double e = 1.0 + mul2;
    const double f = d;

    for (std::size_t t = 1; t <= tsteps; ++t) {
        for (std::size_t i = 1; i < n - 1; ++i) {
            v[i] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = v[i];
            for (std::size_t j = 1; j < n - 1; ++j) {
                p[i * n + j] = -c / (a * p[i * n + j - 1] + b);
                q[i * n + j] = (-d * u[j * n + i - 1] + (1.0 + 2.0 * d) * u[j * n + i]
                                - f * u[j * n + i + 1] - a * q[i * n + j - 1])
                               / (a * p[i * n + j - 1] + b);
            }
            v[(n - 1) * n + i] = 1.0;
            for (std::size_t j = n - 1; j > 1;) {
                --j;
                v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j];
            }
        }

        for (std::size_t i = 1; i < n - 1; ++i) {
            u[i * n] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = u[i * n];
            for (std::size_t j = 1; j < n - 1; ++j) {
                p[i * n + j] = -f / (d * p[i * n + j - 1] + e);
                q[i * n + j] = (-a * v[(i - 1) * n + j] + (1.0 + 2.0 * a) * v[i * n + j]
                                - c * v[(i + 1) * n + j] - d * q[i * n + j - 1])
                               / (d * p[i * n + j - 1] + e);
            }
            u[i * n + n - 1] = 1.0;
            for (std::size_t j = n - 1; j > 1;) {
                --j;
                u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j];
            }
        }
    }

    for (std::size_t index = 0; index < cells; ++index)
        write_f64_le(output, index * 8, u[index]);
    return static_cast<std::int64_t>(output_bytes);
}
