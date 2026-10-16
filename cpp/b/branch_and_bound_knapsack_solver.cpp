/* Breadth-first branch-and-bound for bounded 0/1 knapsack. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 8;
constexpr std::size_t max_nodes = 511;

struct SearchNode {
    std::int32_t level;
    std::int32_t weight;
    std::int32_t value;
    std::int32_t mask;
};

double upper_bound(const std::int32_t *weights, const std::int32_t *item_values,
                   std::int32_t count, std::int32_t capacity,
                   std::int32_t level, std::int32_t weight, std::int32_t value) noexcept {
    auto available = capacity - weight;
    auto bound = static_cast<double>(value);
    auto next = level + 1;
    while (available > 0 && next < count) {
        if (weights[next] <= available) {
            bound += item_values[next];
            available -= weights[next];
        } else {
            bound += (static_cast<double>(item_values[next]) / weights[next]) * available;
            available = 0;
        }
        ++next;
    }
    return bound;
}
}

extern "C" std::int64_t branch_and_bound_knapsack_solver(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 18) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_items)
        || input[1] < 0 || input[1] > 8000) return -1;
    const auto count = static_cast<std::int32_t>(input[0]);
    const auto capacity = static_cast<std::int32_t>(input[1]);
    if (length != 2u + 2u * static_cast<std::size_t>(count)) return -1;

    std::int32_t weights[max_items]{}, item_values[max_items]{}, item_ids[max_items]{};
    for (std::int32_t index = 0; index < count; ++index) {
        const auto weight = input[2 + 2 * index];
        const auto value = input[3 + 2 * index];
        if (weight < 1 || weight > 1000 || value < 1 || value > 1000) return -1;
        auto position = index;
        while (position > 0
               && value * weights[position - 1] > static_cast<std::int64_t>(item_values[position - 1]) * weight) {
            weights[position] = weights[position - 1];
            item_values[position] = item_values[position - 1];
            item_ids[position] = item_ids[position - 1];
            --position;
        }
        weights[position] = static_cast<std::int32_t>(weight);
        item_values[position] = static_cast<std::int32_t>(value);
        item_ids[position] = index;
    }

    SearchNode queue[max_nodes]{};
    std::size_t head = 0, tail = 1;
    queue[0] = {-1, 0, 0, 0};
    std::int32_t best_value = 0, best_mask = 0;
    while (head < tail) {
        const auto parent = queue[head++];
        if (parent.level == count - 1) continue;
        const auto next = parent.level + 1;
        const SearchNode left{next, parent.weight + weights[next],
                              parent.value + item_values[next], parent.mask | (1 << next)};
        const SearchNode right{next, parent.weight, parent.value, parent.mask};
        if (left.weight <= capacity && left.value > best_value) {
            best_value = left.value;
            best_mask = left.mask;
        }
        if (upper_bound(weights, item_values, count, capacity,
                        left.level, left.weight, left.value) > best_value
            && left.weight < capacity) queue[tail++] = left;
        if (upper_bound(weights, item_values, count, capacity,
                        right.level, right.weight, right.value) > best_value)
            queue[tail++] = right;
    }

    std::uint8_t selected[max_items];
    std::size_t selected_count = 0;
    for (std::int32_t level = count - 1; level >= 0; --level)
        if ((best_mask & (1 << level)) != 0) selected[selected_count++] = static_cast<std::uint8_t>(item_ids[level]);
    if (selected_count > output_capacity || (selected_count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < selected_count; ++index) output[index] = selected[index];
    return static_cast<std::int64_t>(selected_count);
}
