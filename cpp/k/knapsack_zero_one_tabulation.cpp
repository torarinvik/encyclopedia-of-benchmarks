/* Tabulated 0/1 knapsack with one reusable row and portable integer operations. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t knapsack_zero_one_tabulation(const std::int64_t *packed,
                                                       std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > 258) return -1;
    if (packed[0] < 0 || packed[0] > 512 || packed[1] < 0 || packed[1] > 128) return -1;
    const auto capacity = static_cast<std::size_t>(packed[0]);
    const auto item_count = static_cast<std::size_t>(packed[1]);
    if (length != 2 + 2 * item_count) return -1;
    for (std::size_t item = 0; item < item_count; ++item) {
        const auto weight = packed[2 + 2 * item];
        const auto value = packed[3 + 2 * item];
        if (weight < 1 || weight > 4096 || value < 0 || value > 1000000000) return -1;
    }

    std::int64_t dp[513] = {};
    const auto width = capacity + 1;
    const auto steps = item_count * width;
    for (std::size_t step = 0; step < steps; ++step) {
        const auto item = step / width;
        const auto current_capacity = capacity - step % width;
        const auto weight = static_cast<std::size_t>(packed[2 + 2 * item]);
        const auto value = packed[3 + 2 * item];
        if (weight <= current_capacity) {
            const auto candidate = dp[current_capacity - weight] + value;
            if (candidate > dp[current_capacity]) dp[current_capacity] = candidate;
        }
    }
    return dp[capacity];
}
