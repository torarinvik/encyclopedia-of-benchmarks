package fractional_knapsack

import "core:c"

Item :: struct {
    weight: i64,
    profit: i64,
}

// Greedy fractional knapsack with exact fixed-point output.
@(export)
fractional_knapsack_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || length > 258 do return -1
    capacity := values[0]
    item_count_value := values[1]
    if capacity < 0 || capacity > 1000000 || item_count_value < 0 || item_count_value > 128 do return -1
    item_count := int(item_count_value)
    if length != 2 + 2 * c.size_t(item_count) do return -1

    items: [128]Item
    for i := 0; i < item_count; i += 1 {
        weight := values[2 + 2 * i]
        profit := values[3 + 2 * i]
        if weight < 1 || weight > 1000000 || profit < 0 || profit > 1000000 do return -1
        items[i] = Item{weight, profit}
    }

    for i := 1; i < item_count; i += 1 {
        current := items[i]
        position := i
        for position > 0 && items[position - 1].profit * current.weight < current.profit * items[position - 1].weight {
            items[position] = items[position - 1]
            position -= 1
        }
        items[position] = current
    }

    remaining := capacity
    scaled_value: i64 = 0
    for i := 0; i < item_count; i += 1 {
        if remaining == 0 do break
        if remaining >= items[i].weight {
            scaled_value += items[i].profit * 1000000
            remaining -= items[i].weight
        } else {
            scaled_value += items[i].profit * remaining * 1000000 / items[i].weight
            break
        }
    }
    return scaled_value
}
