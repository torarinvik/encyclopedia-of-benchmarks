/* Nonnegative subset existence with descending dynamic programming. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxItems = 64;
constexpr std::int64_t kMaxTarget = 4096;
constexpr std::size_t kWidth = 4097;
}

extern "C" std::int64_t subset_sum_nonnegative_exists(const std::int64_t *input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length == 0 || length > kMaxItems + 1) return -1;
    const auto target = input[0];
    if (target < 0 || target > kMaxTarget) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (input[i] < 0 || input[i] > kMaxTarget) return -1;

    bool reachable[kWidth]{};
    reachable[0] = true;
    for (std::size_t i = 1; i < length; ++i) {
        const auto item = input[i];
        for (std::int64_t sum = target; sum >= item; --sum)
            if (reachable[static_cast<std::size_t>(sum - item)])
                reachable[static_cast<std::size_t>(sum)] = true;
    }
    return reachable[static_cast<std::size_t>(target)] ? 1 : 0;
}
