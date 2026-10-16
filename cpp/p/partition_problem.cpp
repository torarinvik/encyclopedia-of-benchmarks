/* Equal-sum two-way partition using bottom-up subset-sum reachability. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxItems = 16;
constexpr std::int64_t kMaxTotal = 1024;
}

extern "C" std::int64_t partition_problem(const std::int64_t *input,
                                            std::size_t length) noexcept {
    if (input == nullptr || length == 0 || length > kMaxItems) return -1;
    std::int64_t total = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] < 0 || input[index] > 256 || total > kMaxTotal - input[index]) return -1;
        total += input[index];
    }
    if ((total & 1) != 0) return 0;
    const auto target = static_cast<std::size_t>(total / 2);
    bool reachable[static_cast<std::size_t>(kMaxTotal) + 1]{};
    reachable[0] = true;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = static_cast<std::size_t>(input[index]);
        if (value > target) continue;
        for (std::size_t sum = target;; --sum) {
            if (reachable[sum - value]) reachable[sum] = true;
            if (sum == value) break;
        }
    }
    return reachable[target] ? 1 : 0;
}
