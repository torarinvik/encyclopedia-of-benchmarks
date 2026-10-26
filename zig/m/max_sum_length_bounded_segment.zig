const max_n: usize = 32;
const max_input: usize = 35;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn max_sum_length_bounded_segment(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const lower64 = input[1];
    const upper64 = input[2];
    if (n64 < 1 or n64 > 32 or lower64 < 1 or upper64 < lower64 or upper64 > n64 or
        length != 3 + @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    const lower: usize = @intCast(lower64);
    const upper: usize = @intCast(upper64);
    var prefix: [max_n + 1]i64 = [_]i64{0} ** (max_n + 1);
    for (0..n) |i| {
        const value = input[3 + i];
        if (value < -10000 or value > 10000) return -1;
        prefix[i + 1] = prefix[i] + value;
    }
    if (output_opt == null or capacity < 24) return -2;
    const output = output_opt.?;
    var deque: [max_n + 1]usize = [_]usize{0} ** (max_n + 1);
    var head: usize = 0;
    var tail: usize = 0;
    var best_sum: i64 = 0;
    var best_start: usize = 0;
    var best_end: usize = 0;
    var have_best = false;
    for (lower..n + 1) |end| {
        const added = end - lower;
        while (tail > head and prefix[deque[tail - 1]] > prefix[added]) tail -= 1;
        deque[tail] = added;
        tail += 1;
        const earliest = if (end > upper) end - upper else 0;
        while (head < tail and deque[head] < earliest) head += 1;
        const start = deque[head];
        const total = prefix[end] - prefix[start];
        if (!have_best or total > best_sum or
            (total == best_sum and (start < best_start or (start == best_start and end < best_end))) {
            best_sum = total;
            best_start = start;
            best_end = end;
            have_best = true;
        }
    }
    storeI64LE(output, 0, best_sum);
    storeI64LE(output, 8, @intCast(best_start));
    storeI64LE(output, 16, @intCast(best_end));
    return 24;
}
