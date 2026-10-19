const MIN_RUNS: i64 = 1;
const MAX_RUNS: i64 = 100;
const SOLVE_REPETITIONS: usize = 50;
const MAX_OUTPUT_BYTES: usize = 292;

fn tryQueens(
    row: usize,
    columns: *[9]bool,
    diagonal_sum: *[17]bool,
    diagonal_diff: *[15]bool,
    positions: *[9]usize,
) bool {
    var j: usize = 0;
    var found = false;
    while (!found and j != 8) {
        j += 1;
        found = false;
        if (columns.*[j] and diagonal_sum.*[row + j] and diagonal_diff.*[row + 7 - j]) {
            positions.*[row] = j;
            columns.*[j] = false;
            diagonal_sum.*[row + j] = false;
            diagonal_diff.*[row + 7 - j] = false;
            if (row < 8) {
                found = tryQueens(row + 1, columns, diagonal_sum, diagonal_diff, positions);
                if (!found) {
                    columns.*[j] = true;
                    diagonal_sum.*[row + j] = true;
                    diagonal_diff.*[row + 7 - j] = true;
                }
            } else {
                found = true;
            }
        }
    }
    return found;
}

fn doit() bool {
    var a: [9]bool = .{false} ** 9;
    var b: [17]bool = .{false} ** 17;
    var c: [15]bool = .{false} ** 15;
    var x: [9]usize = .{0} ** 9;
    var i: i32 = -7;
    while (i <= 16) : (i += 1) {
        if (i >= 1 and i <= 8) a[@intCast(i)] = true;
        if (i >= 2) b[@intCast(i)] = true;
        if (i <= 7) c[@intCast(i + 7)] = true;
    }
    return tryQueens(1, &a, &b, &c, &x);
}

fn appendText(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, text: []const u8) void {
    for (text) |byte| { buffer[used.*] = byte; used.* += 1; }
}

fn appendInteger(buffer: *[MAX_OUTPUT_BYTES]u8, used: *usize, value: i32) void {
    var remaining = value;
    var reverse: [12]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reverse[count] = @intCast(48 + @mod(remaining, 10));
        count += 1;
        remaining = @divTrunc(remaining, 10);
        if (remaining == 0) break;
    }
    while (count > 0) { count -= 1; buffer[used.*] = reverse[count]; used.* += 1; }
}

export fn stanford_queens(runs: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (runs < MIN_RUNS or runs > MAX_RUNS) return -1;
    if (output_opt == null) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    var used: usize = 0;
    for (0..@intCast(runs)) |run| {
        for (0..SOLVE_REPETITIONS) |_| {
            if (!doit()) appendText(&staged, &used, " Error in Queens.\n");
        }
        appendInteger(&staged, &used, @intCast(run + 1));
        appendText(&staged, &used, "\n");
    }
    if (output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
