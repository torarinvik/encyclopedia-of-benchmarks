#include <cstdint>

extern "C" std::int64_t kth_factor(std::int64_t n_value, std::int64_t k_value) noexcept
{
    if (n_value < 1 || n_value > 10000 || k_value < 1 || k_value > n_value) return -1;
    const std::int32_t n = static_cast<std::int32_t>(n_value);
    const std::int32_t k = static_cast<std::int32_t>(k_value);
    std::int32_t factors_found = 0;
    for (std::int32_t i = 1; i <= n; ++i) {
        if (n % i == 0) {
            ++factors_found;
            if (factors_found == k) return i;
        }
    }
    return -1;
}
