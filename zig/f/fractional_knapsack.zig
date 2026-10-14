// Greedy fractional knapsack with exact fixed-point output.
const MAX_INPUT_VALUES: usize = 258;
const MAX_ITEMS: usize = 128;
const LIMIT: i64 = 1_000_000;
const SCALE: i64 = 1_000_000;

const Item = struct { weight: i64, value: i64 };

export fn fractional_knapsack_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_VALUES) return -1;
    const capacity = values[0];
    const item_count_value = values[1];
    if (capacity < 0 or capacity > LIMIT or item_count_value < 0 or
        item_count_value > MAX_ITEMS) return -1;
    const item_count: usize = @intCast(item_count_value);
    if (length != 2 + 2 * item_count) return -1;

    var items: [MAX_ITEMS]Item = undefined;
    for (0..item_count) |i| {
        const weight = values[2 + 2 * i];
        const value = values[3 + 2 * i];
        if (weight < 1 or weight > LIMIT or value < 0 or value > LIMIT) return -1;
        items[i] = .{ .weight = weight, .value = value };
    }

    var sort_index: usize = 1;
    while (sort_index < item_count) : (sort_index += 1) {
        const current = items[sort_index];
        var position = sort_index;
        while (position > 0 and
            items[position - 1].value * current.weight <
                current.value * items[position - 1].weight) {
            items[position] = items[position - 1];
            position -= 1;
        }
        items[position] = current;
    }

    var remaining = capacity;
    var scaled_value: i64 = 0;
    for (0..item_count) |i| {
        if (remaining == 0) break;
        if (remaining >= items[i].weight) {
            scaled_value += items[i].value * SCALE;
            remaining -= items[i].weight;
        } else {
            scaled_value += @divTrunc(items[i].value * remaining * SCALE, items[i].weight);
            break;
        }
    }
    return scaled_value;
}
