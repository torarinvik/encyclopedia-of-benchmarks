#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_s111_odd_index_neighbor_update(const double *input, std::size_t length,
                                                             double *output, std::size_t capacity) {
    constexpr std::size_t max_n = 64;
    if (input == nullptr || length < 3 || length > 129) return -1;
    const double rn = input[0];
    if (!std::isfinite(rn) || std::trunc(rn) != rn || rn < 1 || rn > max_n) return -1;
    const std::size_t n = static_cast<std::size_t>(rn);
    if (length != 1 + 2 * n) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (!std::isfinite(input[i]) || std::trunc(input[i]) != input[i] || std::abs(input[i]) > 1000) return -1;
    if (output == nullptr || capacity < n) return -2;
    for (std::size_t i = 0; i < n; ++i) output[i] = input[1 + i];
    for (std::size_t i = 1; i < n; i += 2) output[i] = input[i] + input[1 + n + i];
    return static_cast<std::int64_t>(n);
}
