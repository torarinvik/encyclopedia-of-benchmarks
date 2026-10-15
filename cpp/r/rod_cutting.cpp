#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t INVALID_RESULT = -1; }

extern "C" std::int64_t rod_cutting(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return INVALID_RESULT;
    const auto n_value = values[0];
    if (n_value < 1 || n_value > 30) return INVALID_RESULT;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != n + 1) return INVALID_RESULT;
    for (std::size_t i = 0; i < n; ++i) {
        if (values[i + 1] < 1 || values[i + 1] > 1000) return INVALID_RESULT;
    }
    std::int64_t profit[31] = {};
    for (std::size_t rod = 1; rod <= n; ++rod) {
        std::int64_t best = 0;
        for (std::size_t cut = 1; cut <= rod; ++cut) {
            const auto candidate = values[cut] + profit[rod - cut];
            if (candidate > best) best = candidate;
        }
        profit[rod] = best;
    }
    return profit[n];
}
