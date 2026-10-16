/// Breadth-first branch-and-bound for bounded 0/1 knapsack.
const max_items = 8;
const max_nodes = 511;

const SearchNode = struct {
    level: i32,
    weight: i32,
    value: i32,
    mask: i32,
};

fn upperBound(weights: [max_items]i32, item_values: [max_items]i32,
    count: i32, capacity: i32, level: i32, weight: i32, value: i32) f64 {
    var available = capacity - weight;
    var bound: f64 = @floatFromInt(value);
    var next = level + 1;
    while (available > 0 and next < count) : (next += 1) {
        const idx: usize = @intCast(next);
        if (weights[idx] <= available) {
            bound += @floatFromInt(item_values[idx]);
            available -= weights[idx];
        } else {
            bound += (@as(f64, @floatFromInt(item_values[idx]))
                / @as(f64, @floatFromInt(weights[idx]))) * @as(f64, @floatFromInt(available));
            available = 0;
        }
    }
    return bound;
}

pub export fn branch_and_bound_knapsack_solver(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 18) return -1;
    if (input[0] < 0 or input[0] > max_items or input[1] < 0 or input[1] > 8000) return -1;
    const count: i32 = @intCast(input[0]);
    const capacity: i32 = @intCast(input[1]);
    if (length != 2 + 2 * @as(usize, @intCast(count))) return -1;

    var weights: [max_items]i32 = @splat(0);
    var item_values: [max_items]i32 = @splat(0);
    var item_ids: [max_items]i32 = @splat(0);
    for (0..@as(usize, @intCast(count))) |index| {
        const weight = input[2 + 2 * index];
        const value = input[3 + 2 * index];
        if (weight < 1 or weight > 1000 or value < 1 or value > 1000) return -1;
        var position = index;
        while (position > 0 and value * weights[position - 1] > @as(i64, item_values[position - 1]) * weight) {
            weights[position] = weights[position - 1];
            item_values[position] = item_values[position - 1];
            item_ids[position] = item_ids[position - 1];
            position -= 1;
        }
        weights[position] = @intCast(weight);
        item_values[position] = @intCast(value);
        item_ids[position] = @intCast(index);
    }

    var queue: [max_nodes]SearchNode = @splat(.{ .level = 0, .weight = 0, .value = 0, .mask = 0 });
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = .{ .level = -1, .weight = 0, .value = 0, .mask = 0 };
    var best_value: i32 = 0;
    var best_mask: i32 = 0;
    while (head < tail) {
        const parent = queue[head];
        head += 1;
        if (parent.level == count - 1) continue;
        const next: usize = @intCast(parent.level + 1);
        const left = SearchNode{ .level = @intCast(next), .weight = parent.weight + weights[next],
            .value = parent.value + item_values[next], .mask = parent.mask | (@as(i32, 1) << @intCast(next)) };
        const right = SearchNode{ .level = @intCast(next), .weight = parent.weight,
            .value = parent.value, .mask = parent.mask };
        if (left.weight <= capacity and left.value > best_value) {
            best_value = left.value;
            best_mask = left.mask;
        }
        if (upperBound(weights, item_values, count, capacity, left.level, left.weight, left.value)
            > @as(f64, @floatFromInt(best_value)) and left.weight < capacity) {
            queue[tail] = left; tail += 1;
        }
        if (upperBound(weights, item_values, count, capacity, right.level, right.weight, right.value)
            > @as(f64, @floatFromInt(best_value))) {
            queue[tail] = right; tail += 1;
        }
    }

    var selected: [max_items]u8 = @splat(0);
    var selected_count: usize = 0;
    var level: i32 = count - 1;
    while (level >= 0) : (level -= 1) {
        const idx: usize = @intCast(level);
        if ((best_mask & (@as(i32, 1) << @intCast(level))) != 0) {
            selected[selected_count] = @intCast(item_ids[idx]);
            selected_count += 1;
        }
    }
    if (selected_count > output_capacity) return -2;
    for (0..selected_count) |index| output[index] = selected[index];
    return @intCast(selected_count);
}
