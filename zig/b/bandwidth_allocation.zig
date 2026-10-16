const max_users: usize = 64;

pub export fn bandwidth_allocation(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2) return -1;
    const bandwidth = input[0];
    const count_value = input[1];
    if (bandwidth < 0 or bandwidth > 100_000 or count_value < 0 or count_value > 64) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 2 * count) return -1;
    for (0..count) |index| {
        const demand = input[2 + index];
        const value = input[2 + count + index];
        if (demand < 1 or demand > 1_000 or value < 0 or value > 10_000) return -1;
    }

    var ratios: [max_users]f64 = undefined;
    var order: [max_users]usize = undefined;
    for (0..count) |index| {
        ratios[index] = @as(f64, @floatFromInt(input[2 + count + index])) /
            @as(f64, @floatFromInt(input[2 + index]));
        order[index] = index;
    }
    if (count > 1) {
        for (1..count) |index| {
            const key_ratio = ratios[index];
            const key_index = order[index];
            var position = index;
            while (position > 0 and ratios[position - 1] < key_ratio) : (position -= 1) {
                ratios[position] = ratios[position - 1];
                order[position] = order[position - 1];
            }
            ratios[position] = key_ratio;
            order[position] = key_index;
        }
    }

    var remaining = bandwidth;
    var total: i64 = 0;
    for (0..count) |position| {
        const index = order[position];
        const demand = input[2 + index];
        const value = input[2 + count + index];
        if (remaining >= demand) {
            total += value;
            remaining -= demand;
        } else {
            total += @intFromFloat(ratios[position] * @as(f64, @floatFromInt(remaining)));
            break;
        }
    }
    return total;
}
