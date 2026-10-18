#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_samples = 8, max_input = 19, max_output = 12; }

extern "C" std::int64_t pca(const double* input, std::size_t input_length, double* output, std::size_t capacity) {
    if (input == nullptr || input_length < 9 || input_length > max_input || input[1] != 2.0 || input[2] != 1.0) return -1;
    if (input[0] != 3.0 && input[0] != 4.0 && input[0] != 5.0 && input[0] != 6.0 && input[0] != 7.0 && input[0] != 8.0) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (input_length != 3 + 2 * n) return -1;
    std::array<double, max_samples> x{}, y{}, z0{}, z1{};
    double mean0 = 0.0, mean1 = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        x[i] = input[3 + 2 * i]; y[i] = input[4 + 2 * i];
        if (x[i] != x[i] || y[i] != y[i] || std::abs(x[i]) > 1000.0 || std::abs(y[i]) > 1000.0) return -1;
        mean0 += x[i]; mean1 += y[i];
    }
    mean0 /= static_cast<double>(n); mean1 /= static_cast<double>(n);
    double sum0 = 0.0, sum1 = 0.0;
    for (std::size_t i = 0; i < n; ++i) { const double a = x[i] - mean0, b = y[i] - mean1; sum0 += a * a; sum1 += b * b; }
    const double denom = static_cast<double>(n - 1);
    if (sum0 <= 0.0 || sum1 <= 0.0) return -1;
    const double scale0 = std::sqrt(sum0 / denom), scale1 = std::sqrt(sum1 / denom);
    double a = 0.0, b = 0.0, d = 0.0;
    for (std::size_t i = 0; i < n; ++i) { z0[i] = (x[i] - mean0) / scale0; z1[i] = (y[i] - mean1) / scale1; a += z0[i] * z0[i]; b += z0[i] * z1[i]; d += z1[i] * z1[i]; }
    a /= denom; b /= denom; d /= denom;
    const double root = std::sqrt((a - d) * (a - d) + 4.0 * b * b);
    const double lambda0 = 0.5 * (a + d + root), lambda1 = 0.5 * (a + d - root);
    if (lambda0 - lambda1 <= 1e-8) return -1;
    double vx, vy;
    if (b == 0.0) { vx = a >= d ? 1.0 : 0.0; vy = a >= d ? 0.0 : 1.0; }
    else { vx = b; vy = lambda0 - a; const double norm = std::sqrt(vx * vx + vy * vy); if (norm == 0.0) return -1; vx /= norm; vy /= norm; }
    if ((std::abs(vx) >= std::abs(vy) && vx < 0.0) || (std::abs(vy) > std::abs(vx) && vy < 0.0)) { vx = -vx; vy = -vy; }
    std::array<double, max_output> staged{};
    for (std::size_t i = 0; i < n; ++i) staged[i] = z0[i] * vx + z1[i] * vy;
    staged[n] = vx; staged[n + 1] = vy; staged[n + 2] = lambda0; staged[n + 3] = lambda1;
    const std::size_t output_size = n + 4;
    if (output == nullptr || capacity < output_size) return -2;
    for (std::size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_size);
}
