const MAX_ITEMS: usize = 32;
const MAX_TARGET: i64 = 256;
const MAX_WEIGHT: usize = 12;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 35;
const MAX_STATES: usize = 2 * MAX_WEIGHT;

export fn pisinger_bounded_weight_subset_sum(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const target_value = input[1];
    if (n_value < 0 or n_value > @as(i64, @intCast(MAX_ITEMS))
        or target_value < 0 or target_value > MAX_TARGET) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 2) return -1;

    var width: usize = 0;
    for (0..n) |index| {
        const weight_value = input[index + 2];
        if (weight_value < 1 or weight_value > @as(i64, @intCast(MAX_WEIGHT))) return -1;
        width = @max(width, @as(usize, @intCast(weight_value)));
    }
    if (n == 0) return 0;

    const target: usize = @intCast(target_value);
    var prefix_sum: usize = 0;
    var break_index: usize = 0;
    while (break_index < n and prefix_sum + @as(usize, @intCast(input[break_index + 2])) <= target) : (break_index += 1) {
        prefix_sum += @as(usize, @intCast(input[break_index + 2]));
    }
    if (break_index == n) return @as(i64, @intCast(prefix_sum));

    var previous: [MAX_STATES]i32 = @splat(-1);
    var current: [MAX_STATES]i32 = undefined;
    previous[prefix_sum + width - target - 1] = @intCast(break_index);
    for (break_index..n) |item| {
        for (0..2 * width) |slot| current[slot] = previous[slot];
        const weight: usize = @intCast(input[item + 2]);
        for (0..width) |slot| {
            const destination = slot + weight;
            if (previous[slot] > current[destination]) current[destination] = previous[slot];
        }
        var slot = 2 * width - 1;
        while (slot >= width) : (slot -= 1) {
            if (current[slot] >= 0) {
                const first_item: usize = @intCast(@max(0, previous[slot]));
                const stop_item: usize = @intCast(current[slot]);
                var removed = first_item;
                while (removed < stop_item) : (removed += 1) {
                    const removed_weight: usize = @intCast(input[removed + 2]);
                    const reduced = slot - removed_weight;
                    if (@as(i32, @intCast(removed)) > current[reduced]) current[reduced] = @intCast(removed);
                }
            }
        }
        for (0..2 * width) |state| previous[state] = current[state];
    }

    const low: usize = if (target >= width) target - width + 1 else 0;
    var mass = target;
    while (mass >= low) {
        if (previous[mass + width - target - 1] >= 0) return @as(i64, @intCast(mass));
        if (mass == 0) break;
        mass -= 1;
    }
    return 0;
}
