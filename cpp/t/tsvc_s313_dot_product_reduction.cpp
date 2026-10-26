#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_s313_dot_product_reduction(const double *input, std::size_t length,
                                                         double *output, std::size_t capacity) {
    constexpr std::size_t max_n = 64;
    if (input == nullptr || length < 3 || length > 1 + 2 * max_n) return -1;
    const double raw_n = input[0];
    if (!std::isfinite(raw_n) || std::trunc(raw_n) != raw_n || raw_n < 1 || raw_n > max_n) return -1;
    const auto n = static_cast<std::size_t>(raw_n);
    if (length != 1 + 2 * n) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (!std::isfinite(input[i]) || std::trunc(input[i]) != input[i] || std::abs(input[i]) > 1000) return -1;
    if (output == nullptr || capacity < 1) return -2;
    double sum = 0.0;
    for (std::size_t i = 0; i < n; ++i) sum += input[1 + i] * input[1 + n + i];
    output[0] = sum;
    return 1;
}
