#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_vtvtv_triple_product_map(const double *input, std::size_t length,
                                                       double *output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > 193) return -1;
    const double rn = input[0];
    if (!std::isfinite(rn) || std::trunc(rn) != rn || rn < 1 || rn > 64) return -1;
    const std::size_t n = static_cast<std::size_t>(rn);
    if (length != 1 + 3*n) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (!std::isfinite(input[i]) || std::trunc(input[i]) != input[i] || std::abs(input[i]) > 2) return -1;
    if (output == nullptr || capacity < n) return -2;
    for (std::size_t i = 0; i < n; ++i) output[i] = (input[1+i] * input[1+n+i]) * input[1+2*n+i];
    return static_cast<std::int64_t>(n);
}
