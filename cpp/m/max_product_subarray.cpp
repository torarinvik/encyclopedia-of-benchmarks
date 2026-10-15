// Maximum contiguous product with current maximum/minimum tracking.
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t max_product_subarray(const std::int64_t *values, std::size_t length) noexcept {
    constexpr auto invalid = std::numeric_limits<std::int64_t>::min();
    if (length > 9 || (length > 0 && values == nullptr)) return invalid;
    if (length == 0) return 0;
    if (values[0] < -10 || values[0] > 10) return invalid;
    std::int64_t max_now = values[0], min_now = values[0], max_product = values[0];
    for (std::size_t i = 1; i < length; ++i) {
        const auto value = values[i];
        if (value < -10 || value > 10) return invalid;
        if (value < 0) { const auto swap = max_now; max_now = min_now; min_now = swap; }
        auto product = max_now * value;
        max_now = value > product ? value : product;
        product = min_now * value;
        min_now = value < product ? value : product;
        if (max_now > max_product) max_product = max_now;
    }
    return max_product;
}
