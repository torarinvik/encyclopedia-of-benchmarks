/* Clean-room bounded knapsack by binary grouping. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_types = 16;
constexpr std::size_t max_capacity = 64;
constexpr std::size_t max_input = 51;
}

extern "C" std::int64_t bounded_knapsack_binary_grouping(
    const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0];
    const auto capacity_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_types)
        || capacity_value < 0 || capacity_value > static_cast<std::int64_t>(max_capacity)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto capacity = static_cast<std::size_t>(capacity_value);
    if (length != 2 + 3 * n) return -1;
    for (std::size_t item = 0; item < n; ++item) {
        const auto weight = input[2 + 3 * item];
        const auto value = input[3 + 3 * item];
        const auto count = input[4 + 3 * item];
        if (weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16) return -1;
    }

    std::int64_t best[max_capacity + 1]{};
    for (std::size_t item = 0; item < n; ++item) {
        const auto weight = static_cast<std::size_t>(input[2 + 3 * item]);
        const auto value = input[3 + 3 * item];
        auto remaining = static_cast<std::size_t>(input[4 + 3 * item]);
        std::size_t bundle_size = 1;
        while (remaining > 0) {
            const auto copies = bundle_size < remaining ? bundle_size : remaining;
            const auto bundle_weight = weight * copies;
            const auto bundle_value = value * static_cast<std::int64_t>(copies);
            if (bundle_weight <= capacity) {
                for (std::size_t limit = capacity; limit >= bundle_weight; --limit) {
                    const auto candidate = best[limit - bundle_weight] + bundle_value;
                    if (candidate > best[limit]) best[limit] = candidate;
                }
            }
            remaining -= copies;
            bundle_size *= 2;
        }
    }
    return best[capacity];
}
