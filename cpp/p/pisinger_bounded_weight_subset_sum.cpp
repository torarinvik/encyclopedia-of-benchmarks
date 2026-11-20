/* Clean-room Pisinger balanced-state subset-sum profile. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 32;
constexpr std::size_t max_parseable_input_length = 35;
constexpr std::int64_t max_target = 256;
constexpr std::int64_t max_weight = 12;
}

extern "C" std::int64_t pisinger_bounded_weight_subset_sum(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t target_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_items)
        || target_value < 0 || target_value > max_target) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != n + 2) return -1;

    std::int32_t width = 0;
    for (std::size_t index = 0; index < n; ++index) {
        const auto weight = input[index + 2];
        if (weight < 1 || weight > max_weight) return -1;
        if (weight > width) width = static_cast<std::int32_t>(weight);
    }
    if (n == 0) return 0;

    const auto target = static_cast<std::int32_t>(target_value);
    std::int32_t prefix_sum = 0;
    std::size_t break_index = 0;
    while (break_index < n && prefix_sum + input[break_index + 2] <= target) {
        prefix_sum += static_cast<std::int32_t>(input[break_index + 2]);
        ++break_index;
    }
    if (break_index == n) return prefix_sum;

    std::int32_t previous[2 * max_weight];
    std::int32_t current[2 * max_weight];
    for (std::int32_t slot = 0; slot < 2 * width; ++slot) previous[slot] = -1;
    previous[prefix_sum + width - target - 1] = static_cast<std::int32_t>(break_index);

    for (std::size_t item = break_index; item < n; ++item) {
        for (std::int32_t slot = 0; slot < 2 * width; ++slot) current[slot] = previous[slot];
        const auto weight = static_cast<std::int32_t>(input[item + 2]);
        for (std::int32_t slot = 0; slot < width; ++slot) {
            const auto destination = slot + weight;
            if (previous[slot] > current[destination]) current[destination] = previous[slot];
        }
        for (std::int32_t slot = 2 * width - 1; slot >= width; --slot) {
            std::int32_t first_item = previous[slot];
            if (first_item < 0) first_item = 0;
            const auto stop_item = current[slot];
            for (std::int32_t removed = first_item; removed < stop_item; ++removed) {
                const auto reduced = slot - static_cast<std::int32_t>(input[static_cast<std::size_t>(removed) + 2]);
                if (removed > current[reduced]) current[reduced] = removed;
            }
        }
        for (std::int32_t slot = 0; slot < 2 * width; ++slot) previous[slot] = current[slot];
    }

    const std::int32_t low_mass = target >= width ? target - width + 1 : 0;
    for (std::int32_t mass = target; mass >= low_mass; --mass) {
        if (previous[mass + width - target - 1] >= 0) return mass;
    }
    return 0;
}
