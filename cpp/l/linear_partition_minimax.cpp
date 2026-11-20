#include <cstddef>
#include <cstdint>

namespace {
bool feasible(const std::int64_t *input, std::size_t n, std::size_t groups,
              std::int64_t limit) noexcept {
    std::size_t used_groups = 1;
    std::int64_t current_sum = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t value = input[i + 2];
        if (current_sum + value > limit) {
            ++used_groups;
            current_sum = value;
            if (used_groups > groups) return false;
        } else {
            current_sum += value;
        }
    }
    return true;
}
}

extern "C" std::int64_t linear_partition_minimax(const std::int64_t *input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 35) return -1;
    if (input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > input[0]) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t groups = static_cast<std::size_t>(input[1]);
    if (length != n + 2) return -1;

    std::int64_t low = 0;
    std::int64_t high = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t value = input[i + 2];
        if (value < 0 || value > 1000) return -1;
        if (value > low) low = value;
        high += value;
    }
    while (low < high) {
        const std::int64_t middle = low + (high - low) / 2;
        if (feasible(input, n, groups, middle)) high = middle;
        else low = middle + 1;
    }
    return low;
}
