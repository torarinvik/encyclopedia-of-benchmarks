module fractional_knapsack;

// Greedy fractional knapsack with exact fixed-point output.
fn long fractional_knapsack_benchmark(long* values, usz length) @export("fractional_knapsack_benchmark")
{
    if (length < 2 || length > 258) return -1;
    long capacity = values[0];
    long item_count_value = values[1];
    if (capacity < 0 || capacity > 1000000 || item_count_value < 0 || item_count_value > 128) return -1;
    usz item_count = (usz)item_count_value;
    if (length != 2 + 2 * item_count) return -1;

    long[128] weights;
    long[128] profits;
    for (usz i = 0; i < item_count; i++) {
        long weight = values[2 + 2 * i];
        long profit = values[3 + 2 * i];
        if (weight < 1 || weight > 1000000 || profit < 0 || profit > 1000000) return -1;
        weights[i] = weight;
        profits[i] = profit;
    }

    for (usz i = 1; i < item_count; i++) {
        long current_weight = weights[i];
        long current_profit = profits[i];
        usz position = i;
        while (position > 0 &&
               profits[position - 1] * current_weight <
                   current_profit * weights[position - 1]) {
            weights[position] = weights[position - 1];
            profits[position] = profits[position - 1];
            position--;
        }
        weights[position] = current_weight;
        profits[position] = current_profit;
    }

    long remaining = capacity;
    long scaled_value = 0;
    for (usz i = 0; i < item_count && remaining > 0; i++) {
        if (remaining >= weights[i]) {
            scaled_value += profits[i] * 1000000;
            remaining -= weights[i];
        } else {
            scaled_value += profits[i] * remaining * 1000000 / weights[i];
            break;
        }
    }
    return scaled_value;
}
