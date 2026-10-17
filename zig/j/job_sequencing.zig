const MAX_JOBS: usize = 32;
const MAX_JOBS_I64: i64 = 32;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_JOBS + 1;
const MAX_PROFIT: i64 = 1_000_000;

export fn job_sequencing(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > MAX_JOBS_I64) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 3 * n) return -1;
    var seen = [_]bool{false} ** 128;
    var previous_profit: i64 = MAX_PROFIT + 1;
    for (0..n) |index| {
        const base = 1 + 3 * index;
        const id, deadline, profit = .{ values[base], values[base + 1], values[base + 2] };
        const letter = (id >= 65 and id <= 90) or (id >= 97 and id <= 122);
        if (!letter or seen[@intCast(id)] or deadline < 1 or deadline > @as(i64, @intCast(n)) or profit < 1 or profit > MAX_PROFIT or profit >= previous_profit) return -1;
        seen[@intCast(id)] = true; previous_profit = profit;
    }
    var slots = [_]u8{0} ** MAX_JOBS;
    var total_profit: i64 = 0;
    for (0..n) |index| {
        const base = 1 + 3 * index;
        const deadline: usize = @intCast(values[base + 1]);
        var remaining = deadline;
        while (remaining > 0) {
            remaining -= 1;
            if (slots[remaining] == 0) { slots[remaining] = @intCast(values[base]); total_profit += values[base + 2]; break; }
        }
    }
    var count: usize = 0; for (slots[0..n]) |id| { if (id != 0) count += 1; }
    const required = 9 + count;
    if (output == null or capacity < required) return -2;
    const result = output.?[0..capacity];
    result[0] = @intCast(count);
    const profit_bits: u64 = @intCast(total_profit);
    for (0..8) |byte| result[1 + byte] = @truncate(profit_bits >> @as(u6, @intCast(8 * byte)));
    var written: usize = 9; for (slots[0..n]) |id| { if (id != 0) { result[written] = id; written += 1; } }
    return @intCast(required);
}
