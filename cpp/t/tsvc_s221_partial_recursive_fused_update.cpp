#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_s221_partial_recursive_fused_update(const double *input, std::size_t length,
                                                                  double *output, std::size_t capacity) {
    if (input == nullptr || length < 5 || length > 257) return -1;
    const double rn = input[0];
    if (!std::isfinite(rn) || std::trunc(rn) != rn || rn < 1 || rn > 64) return -1;
    const std::size_t n = static_cast<std::size_t>(rn);
    if (length != 1 + 4*n) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (!std::isfinite(input[i]) || std::trunc(input[i]) != input[i] || std::abs(input[i]) > 2) return -1;
    const std::size_t required = 2*n;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < n; ++i) { output[i] = input[1+i]; output[n+i] = input[1+n+i]; }
    for (std::size_t i = 1; i < n; ++i) {
        output[i] = output[i] + input[1+2*n+i] * input[1+3*n+i];
        output[n+i] = (output[n+i-1] + output[i]) + input[1+3*n+i];
    }
    return static_cast<std::int64_t>(required);
}
