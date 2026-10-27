const MaxText: usize = 24;
const MaxInput: usize = 26;
const MaxOutput: usize = 34504;

fn mismatchCount(input: []const i64, start: usize, factorLength: usize, period: usize) usize {
    var count: usize = 0;
    for (0..factorLength - period) |offset| {
        if (input[2 + start + offset] != input[2 + start + offset + period]) count += 1;
    }
    return count;
}
fn countRecords(input: []const i64, n: usize, budget: usize) usize {
    var count: usize = 0;
    for (0..n) |start| {
        const remaining = n - start;
        var period: usize = 1;
        while (2 * period + 1 <= remaining) : (period += 1) {
            var factorLength = 2 * period + 1;
            while (factorLength <= remaining) : (factorLength += 1) {
                if (mismatchCount(input, start, factorLength, period) <= budget) count += 1;
            }
        }
    }
    return count;
}
fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn approximate_tandem_k_repetitions(input_opt: ?[*]const i64, length: usize,
                                           output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MaxInput) return -1;
    const input = input_opt.?;
    const n0 = input[0];
    const budget0 = input[1];
    if (n0 < 3 or n0 > @as(i64, @intCast(MaxText)) or budget0 < 0 or budget0 > 8
        or length != @as(usize, @intCast(n0)) + 2) return -1;
    const n: usize = @intCast(n0);
    const budget: usize = @intCast(budget0);
    const words = input[0 .. n + 2];
    for (words[2..]) |symbol| if (symbol < 0 or symbol > 3) return -1;
    const count = countRecords(words, n, budget);
    const bytes = 8 * (1 + 4 * count);
    if (bytes > MaxOutput) return -1;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, @intCast(count));
    var record: usize = 0;
    for (0..n) |start| {
        const remaining = n - start;
        var period: usize = 1;
        while (2 * period + 1 <= remaining) : (period += 1) {
            var factorLength = 2 * period + 1;
            while (factorLength <= remaining) : (factorLength += 1) {
                const errors = mismatchCount(words, start, factorLength, period);
                if (errors <= budget) {
                    const offset = 8 * (1 + 4 * record);
                    storeI64Le(output, offset, @intCast(start));
                    storeI64Le(output, offset + 8, @intCast(factorLength));
                    storeI64Le(output, offset + 16, @intCast(period));
                    storeI64Le(output, offset + 24, @intCast(errors));
                    record += 1;
                }
            }
        }
    }
    return @intCast(bytes);
}
