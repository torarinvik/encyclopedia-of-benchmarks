const MAX_PATTERN: usize = 16;
const MAX_TEXT: usize = 32;
const MAX_ERRORS: usize = 2;
const MAX_VALID_INPUT: usize = 3 + MAX_PATTERN + MAX_TEXT;
const MAX_PARSEABLE_INPUT: usize = MAX_VALID_INPUT + 1;
const DIAGONALS: usize = MAX_TEXT + MAX_ERRORS + 3;
const COSTS: usize = MAX_ERRORS + 2;

fn diagonalSlot(diagonal: isize) usize {
    return @intCast(diagonal + @as(isize, @intCast(MAX_ERRORS)) + 1);
}

export fn landau_vishkin_k_difference_pattern_matching(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 3 or length > MAX_PARSEABLE_INPUT) return -1;
    const raw_m = input[0];
    const raw_n = input[1];
    const raw_k = input[2];
    if (raw_m < 1 or raw_m > MAX_PATTERN or raw_n < 0 or raw_n > MAX_TEXT or
        raw_k < 0 or raw_k > MAX_ERRORS or raw_k >= raw_m) return -1;
    const m: usize = @intCast(raw_m);
    const n: usize = @intCast(raw_n);
    const k: usize = @intCast(raw_k);
    if (length != 3 + m + n) return -1;
    for (0..m + n) |index| {
        const symbol = input[3 + index];
        if (symbol < 0 or symbol > 3) return -1;
    }
    const output = output_opt orelse return -2;
    if (capacity < n) return -2;

    var frontier: [DIAGONALS][COSTS]i64 = undefined;
    for (0..DIAGONALS) |diagonal| {
        for (0..COSTS) |cost| frontier[diagonal][cost] = -1;
    }
    const signed_k: isize = @intCast(k);
    for (-(signed_k + 1)..0) |d| {
        const magnitude: usize = @intCast(-d);
        const base = diagonalSlot(d);
        frontier[base][magnitude] = @intCast(magnitude - 1);
        frontier[base][magnitude - 1] = @as(i64, @intCast(magnitude)) - 2;
    }

    var staged: [MAX_TEXT]u8 = .{0} ** MAX_TEXT;
    const signed_n: isize = @intCast(n);
    for (0..k + 1) |errors| {
        const signed_errors: isize = @intCast(errors);
        for (-signed_errors..signed_n + 1) |d| {
            const base = diagonalSlot(d);
            var row = @max(frontier[base][errors] + 1,
                @max(frontier[base - 1][errors], frontier[base + 1][errors] + 1));
            row = @min(row, raw_m);
            while (row < raw_m) {
                const text_index = row + @as(i64, @intCast(d));
                if (text_index < 0 or text_index >= raw_n or
                    input[3 + @as(usize, @intCast(row))] !=
                    input[3 + m + @as(usize, @intCast(text_index))]) break;
                row += 1;
            }
            frontier[base][errors + 1] = row;
            if (row == raw_m) {
                const endpoint = d + @as(isize, @intCast(m));
                if (endpoint >= 1 and endpoint <= signed_n) {
                    staged[@intCast(endpoint - 1)] = 1;
                }
            }
        }
    }
    @memcpy(output[0..n], staged[0..n]);
    return @intCast(n);
}
