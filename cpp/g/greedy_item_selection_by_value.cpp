#include <cstddef>
#include <cstdint>

namespace { constexpr int max_items = 8; }

extern "C" std::int64_t greedy_item_selection_by_value(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 18) return -1;
    const auto capacity = values[0], count_value = values[1];
    if (capacity < 0 || capacity > 1000000 || count_value < 0 || count_value > max_items ||
        length != 2 + 2 * static_cast<std::size_t>(count_value)) return -1;
    const int count = static_cast<int>(count_value);
    std::int64_t item_values[max_items]{}, weights[max_items]{};
    int order[max_items]{};
    for (int index = 0; index < count; ++index) {
        item_values[index] = values[2 + static_cast<std::size_t>(index)];
        weights[index] = values[2 + static_cast<std::size_t>(count) + static_cast<std::size_t>(index)];
        if (item_values[index] < 0 || item_values[index] > 1000000 || weights[index] < 1 || weights[index] > 1000000) return -1;
        order[index] = index;
    }
    for (int index = 1; index < count; ++index) {
        const int current = order[index];
        int position = index;
        while (position > 0 && item_values[order[position - 1]] < item_values[current]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }
    std::int64_t total_weight = 0, total_value = 0, sequence = 0;
    int selected = 0;
    for (int index = 0; index < count; ++index) {
        const int item = order[index];
        if (total_weight + weights[item] <= capacity) {
            sequence |= static_cast<std::int64_t>(item + 1) << (4 * selected);
            ++selected;
            total_weight += weights[item];
            total_value += item_values[item];
        }
    }
    return (total_value << 36) | (static_cast<std::int64_t>(selected) << 32) | sequence;
}
