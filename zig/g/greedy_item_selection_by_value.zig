const MAX_ITEMS: usize = 8;

export fn greedy_item_selection_by_value(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 18) return -1;
    const values = input;
    const capacity = values[0];
    const count_value = values[1];
    if (capacity < 0 or capacity > 1_000_000 or count_value < 0 or count_value > MAX_ITEMS) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 2 * count) return -1;
    var item_values: [MAX_ITEMS]i64 = @splat(0);
    var weights: [MAX_ITEMS]i64 = @splat(0);
    var order: [MAX_ITEMS]usize = @splat(0);
    for (0..count) |index| {
        item_values[index] = values[2 + index];
        weights[index] = values[2 + count + index];
        if (item_values[index] < 0 or item_values[index] > 1_000_000 or weights[index] < 1 or weights[index] > 1_000_000) return -1;
        order[index] = index;
    }
    for (1..count) |index| {
        const current = order[index];
        var position = index;
        while (position > 0 and item_values[order[position - 1]] < item_values[current]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }
    var total_weight: i64 = 0;
    var total_value: i64 = 0;
    var sequence: u64 = 0;
    var selected: usize = 0;
    for (0..count) |index| {
        const item = order[index];
        if (total_weight + weights[item] <= capacity) {
            sequence |= @as(u64, @intCast(item + 1)) << @intCast(4 * selected);
            selected += 1;
            total_weight += weights[item];
            total_value += item_values[item];
        }
    }
    return @intCast((@as(u64, @intCast(total_value)) << 36) | (@as(u64, @intCast(selected)) << 32) | sequence);
}
