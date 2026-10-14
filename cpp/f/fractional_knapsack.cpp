// Greedy fractional knapsack with exact fixed-point output.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_values = 258;
constexpr std::size_t max_items = 128;
constexpr std::int64_t limit = 1'000'000;
constexpr std::int64_t scale = 1'000'000;
struct Item { std::int64_t weight, value; };
}

extern "C" std::int64_t fractional_knapsack_benchmark(const std::int64_t *values,
                                                       std::size_t length) noexcept
{
    if (length < 2 || length > max_input_values) return -1;
    const auto capacity = values[0], item_count_value = values[1];
    if (capacity < 0 || capacity > limit || item_count_value < 0 ||
        item_count_value > static_cast<std::int64_t>(max_items)) return -1;
    const auto item_count = static_cast<std::size_t>(item_count_value);
    if (length != 2 + 2 * item_count) return -1;

    Item items[max_items]{};
    for (std::size_t i = 0; i < item_count; ++i) {
        const auto weight = values[2 + 2 * i], value = values[3 + 2 * i];
        if (weight < 1 || weight > limit || value < 0 || value > limit) return -1;
        items[i] = {weight, value};
    }

    for (std::size_t i = 1; i < item_count; ++i) {
        const Item current = items[i];
        std::size_t position = i;
        while (position > 0 &&
               items[position - 1].value * current.weight <
                   current.value * items[position - 1].weight) {
            items[position] = items[position - 1];
            --position;
        }
        items[position] = current;
    }

    auto remaining = capacity;
    std::int64_t scaled_value = 0;
    for (std::size_t i = 0; i < item_count && remaining > 0; ++i) {
        if (remaining >= items[i].weight) {
            scaled_value += items[i].value * scale;
            remaining -= items[i].weight;
        } else {
            scaled_value += items[i].value * remaining * scale / items[i].weight;
            break;
        }
    }
    return scaled_value;
}
