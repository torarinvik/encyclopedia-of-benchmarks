#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 10000;
constexpr std::int64_t output_count = 9;
}

extern "C" std::int64_t partialsums(const double *input, std::size_t length,
                                     double *output, std::size_t capacity) {
    if (input == nullptr || length != 1 || !std::isfinite(input[0]) ||
        std::trunc(input[0]) != input[0] || input[0] < 1.0 || input[0] > max_n) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    double geometric = 0.0, inverse_sqrt = 0.0, flint = 0.0, cookson = 0.0;
    double telescoping[2]{}, harmonic[2]{}, zeta[2]{}, alternating[2]{}, gregory[2]{};
    double term = 1.0;
    const std::size_t vector_limit = n + (n & 1);
    for (std::size_t k = 1; k <= vector_limit; ++k) {
        const double kd = static_cast<double>(k);
        const std::size_t lane = (k - 1) & 1;
        if (k <= n) {
            const double k3 = kd * kd * kd;
            const double s = std::sin(kd), c = std::cos(kd);
            geometric += term;
            term *= 2.0 / 3.0;
            inverse_sqrt += 1.0 / std::sqrt(kd);
            flint += 1.0 / (k3 * s * s);
            cookson += 1.0 / (k3 * c * c);
        }
        telescoping[lane] += 1.0 / (kd * (kd + 1.0));
        harmonic[lane] += 1.0 / kd;
        zeta[lane] += 1.0 / (kd * kd);
        alternating[lane] += (lane == 0 ? 1.0 : -1.0) / kd;
        gregory[lane] += (lane == 0 ? 1.0 : -1.0) / (2.0 * kd - 1.0);
    }
    if (output == nullptr || capacity < static_cast<std::size_t>(output_count)) return -2;
    output[0] = geometric;
    output[1] = inverse_sqrt;
    output[2] = telescoping[0] + telescoping[1];
    output[3] = flint;
    output[4] = cookson;
    output[5] = harmonic[0] + harmonic[1];
    output[6] = zeta[0] + zeta[1];
    output[7] = alternating[0] + alternating[1];
    output[8] = gregory[0] + gregory[1];
    return output_count;
}
