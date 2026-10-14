module fractional_knapsack

struct KnapsackItem {
    weight i64
    profit i64
}

// Greedy fractional knapsack with exact fixed-point output.
@[export: 'fractional_knapsack_benchmark']
pub fn fractional_knapsack_benchmark(values &i64, length usize) i64 {
    if length < 2 || length > 258 { return -1 }
    capacity := unsafe { values[0] }
    item_count_value := unsafe { values[1] }
    if capacity < 0 || capacity > 1000000 || item_count_value < 0 || item_count_value > 128 { return -1 }
    item_count := int(item_count_value)
    if int(length) != 2 + 2 * item_count { return -1 }

    mut items := [128]KnapsackItem{}
    for i in 0 .. item_count {
        weight := unsafe { values[2 + 2 * i] }
        profit := unsafe { values[3 + 2 * i] }
        if weight < 1 || weight > 1000000 || profit < 0 || profit > 1000000 { return -1 }
        items[i] = KnapsackItem{weight, profit}
    }

    for i in 1 .. item_count {
        current := items[i]
        mut position := i
        for position > 0 && items[position - 1].profit * current.weight < current.profit * items[position - 1].weight {
            items[position] = items[position - 1]
            position--
        }
        items[position] = current
    }

    mut remaining := capacity
    mut scaled_value := i64(0)
    for i in 0 .. item_count {
        if remaining == 0 { break }
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
