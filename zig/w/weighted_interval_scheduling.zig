const MAX_INTERVALS: usize = 64;
const MAX_INPUT_LENGTH: usize = 193;

fn startAt(input: [*c]const i64, index: usize) i64 { return input[1 + index * 3]; }
fn endAt(input: [*c]const i64, index: usize) i64 { return input[2 + index * 3]; }
fn weightAt(input: [*c]const i64, index: usize) i64 { return input[3 + index * 3]; }

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}
fn putI32Le(output: [*c]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn weighted_interval_scheduling(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH or input[0] < 0 or input[0] > MAX_INTERVALS) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 3 * n) return -1;
    for (0..n) |i| {
        const start = startAt(input, i);
        const finish = endAt(input, i);
        const weight = weightAt(input, i);
        if (start < -100_000 or start > 100_000 or finish < -100_000 or finish > 100_000
            or start >= finish or weight < 0 or weight > 1_000_000) return -1;
    }
    var order: [MAX_INTERVALS]usize = @splat(0);
    var predecessors: [MAX_INTERVALS]usize = @splat(0);
    var selected: [MAX_INTERVALS]usize = @splat(0);
    var dp: [MAX_INTERVALS + 1]i64 = @splat(0);
    for (0..n) |i| order[i] = i;
    if (n > 1) {
        for (1..n) |i| {
            const key = order[i];
            var j = i;
            while (j > 0 and endAt(input, order[j - 1]) > endAt(input, key)) : (j -= 1) order[j] = order[j - 1];
            order[j] = key;
        }
    }
    for (0..n) |j| {
        var low: usize = 0;
        var high = n;
        while (low < high) {
            const mid = low + (high - low) / 2;
            if (endAt(input, order[mid]) <= startAt(input, order[j])) low = mid + 1 else high = mid;
        }
        predecessors[j] = low;
        const include = weightAt(input, order[j]) + dp[low];
        dp[j + 1] = if (include > dp[j]) include else dp[j];
    }
    var selected_count: usize = 0;
    var current = n;
    while (current > 0) {
        const j = current - 1;
        const include = weightAt(input, order[j]) + dp[predecessors[j]];
        if (include > dp[current - 1]) {
            selected[selected_count] = order[j];
            selected_count += 1;
            current = predecessors[j];
        } else current -= 1;
    }
    for (0..selected_count / 2) |i| {
        const temp = selected[i];
        selected[i] = selected[selected_count - 1 - i];
        selected[selected_count - 1 - i] = temp;
    }
    const needed = 16 + 4 * selected_count;
    if (output == null or capacity < needed) return -2;
    putI64Le(output, 0, dp[n]);
    putI64Le(output, 8, @intCast(selected_count));
    for (0..selected_count) |i| putI32Le(output, 16 + 4 * i, @intCast(selected[i]));
    return @intCast(needed);
}
