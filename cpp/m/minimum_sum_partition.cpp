/* Minimum partition difference with bottom-up subset-sum reachability. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_valid_input_length = 64;
constexpr std::int64_t max_total_sum = 4096;
}

extern "C" std::int64_t minimum_sum_partition(const std::int64_t *input,
                                               std::size_t length) noexcept {
    if (length > max_valid_input_length || (input == nullptr && length != 0)) return -1;

    std::int64_t total = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = input[index];
        if (value < 0 || value > max_total_sum || total > max_total_sum - value) return -1;
        total += value;
    }

    const std::size_t target = static_cast<std::size_t>(total / 2);
    std::uint8_t reachable[max_total_sum / 2 + 1]{};
    reachable[0] = 1;
    std::size_t closest = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::size_t value = static_cast<std::size_t>(input[index]);
        for (std::size_t sum = target; sum > 0; --sum) {
            if (value <= sum && reachable[sum - value] != 0) reachable[sum] = 1;
            if (reachable[sum] != 0 && sum > closest) closest = sum;
        }
    }
    return total - 2 * static_cast<std::int64_t>(closest);
}
