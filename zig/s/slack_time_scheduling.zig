const MAX_N: usize = 64;
const MAX_TIME: i64 = 1_000_000;

export fn slack_time_scheduling(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 1 + 2 * MAX_N) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > MAX_N) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 2 * n) return -1;
    var slack: [MAX_N]i64 = undefined;
    var order: [MAX_N]usize = undefined;
    for (0..n) |i| {
        const execution = values[1 + 2 * i];
        const deadline = values[2 + 2 * i];
        if (execution < 0 or execution > MAX_TIME or deadline < 0 or deadline > MAX_TIME) return -1;
        slack[i] = deadline - execution;
        order[i] = i;
    }
    const bytes = 8 * n;
    if (output == null or capacity < bytes) return -2;
    if (n > 1) {
        for (1..n) |i| {
            const key = order[i];
            var j = i;
            while (j > 0 and slack[key] < slack[order[j - 1]]) : (j -= 1) { order[j] = order[j - 1]; }
            order[j] = key;
        }
    }
    const destination = output.?;
    for (0..n) |i| {
        const bits: u64 = order[i];
        for (0..8) |byte| destination[i * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(bytes);
}
