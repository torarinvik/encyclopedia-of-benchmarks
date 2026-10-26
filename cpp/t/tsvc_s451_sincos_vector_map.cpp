#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_s451_sincos_vector_map(const double *input, std::size_t length,
                                                      double *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 129) return -1;
    const double rn = input[0];
    if (!std::isfinite(rn) || std::trunc(rn) != rn || rn < 1 || rn > 64) return -1;
    const std::size_t n = static_cast<std::size_t>(rn);
    if (length != 1 + 2*n) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (!std::isfinite(input[i]) || std::abs(input[i]) > 10) return -1;
    if (output == nullptr || capacity < n) return -2;
    for (std::size_t i = 0; i < n; ++i) output[i] = std::sin(input[1+i]) + std::cos(input[1+n+i]);
    return static_cast<std::int64_t>(n);
}
