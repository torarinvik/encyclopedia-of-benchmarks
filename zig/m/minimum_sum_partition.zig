const MAX_VALID_INPUT_LENGTH: usize = 64;
const MAX_TOTAL_SUM: usize = 4096;

export fn minimum_sum_partition(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_VALID_INPUT_LENGTH or (input == null and length != 0)) return -1;

    var total: i64 = 0;
    for (0..length) |index| {
        const value = input[index];
        if (value < 0 or value > @as(i64, @intCast(MAX_TOTAL_SUM))
            or total > @as(i64, @intCast(MAX_TOTAL_SUM)) - value) return -1;
        total += value;
    }

    const target: usize = @intCast(@divTrunc(total, 2));
    var reachable: [MAX_TOTAL_SUM / 2 + 1]bool = @splat(false);
    reachable[0] = true;
    var closest: usize = 0;
    for (0..length) |index| {
        const value: usize = @intCast(input[index]);
        var sum = target;
        while (sum > 0) : (sum -= 1) {
            if (value <= sum and reachable[sum - value]) reachable[sum] = true;
            if (reachable[sum] and sum > closest) closest = sum;
        }
    }
    return total - 2 * @as(i64, @intCast(closest));
}
