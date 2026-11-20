const MAX_CELLS: usize = 64;
const MAX_INPUT: usize = 1095;

fn putWord(output: [*]u8, word: usize, value: i64) void {
    const bytes = @as(u64, @bitCast(value));
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bytes >> @intCast(byte * 8));
}

export fn forest_fire_synchronous_stochastic_ca(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 6 or length > MAX_INPUT) return -1;
    if (input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8 or
        input[2] < 0 or input[2] > 8 or input[3] != 10000 or
        input[4] < 0 or input[4] > 10000 or input[5] < 0 or input[5] > 10000) return -1;
    const rows: usize = @intCast(input[0]);
    const cols: usize = @intCast(input[1]);
    const steps: usize = @intCast(input[2]);
    const cells = rows * cols;
    if (length != 6 + cells + 2 * steps * cells) return -1;
    for (0..cells) |i| {
        if (input[6 + i] < 0 or input[6 + i] > 2) return -1;
    }
    for (0..rows) |row| {
        for (0..cols) |col| {
            if ((row == 0 or row + 1 == rows or col == 0 or col + 1 == cols) and input[6 + row * cols + col] != 0) return -1;
        }
    }
    const tape = 6 + cells;
    for (0..2 * steps * cells) |i| {
        if (input[tape + i] < 0 or input[tape + i] >= 10000) return -1;
    }
    const bytes = (1 + 3 * steps + cells) * 8;
    if (output == null or capacity < bytes) return -2;
    const out = output[0..bytes];

    var current: [MAX_CELLS]u8 = @splat(0);
    var next: [MAX_CELLS]u8 = @splat(0);
    for (0..cells) |i| current[i] = @intCast(input[6 + i]);
    putWord(out.ptr, 0, @intCast(steps));
    for (0..steps) |tick| {
        for (0..rows) |row| {
            for (0..cols) |col| {
                const site = row * cols + col;
                if (row == 0 or row + 1 == rows or col == 0 or col + 1 == cols) { next[site] = 0; continue; }
                if (current[site] == 2) { next[site] = 0; continue; }
                if (current[site] == 0) {
                    next[site] = if (input[tape + tick * cells + site] < input[4]) 1 else 0;
                    continue;
                }
                var adjacent = false;
                const r0 = if (row == 0) 0 else row - 1;
                const r1 = @min(rows - 1, row + 1);
                const c0 = if (col == 0) 0 else col - 1;
                const c1 = @min(cols - 1, col + 1);
                for (r0..r1 + 1) |rr| {
                    for (c0..c1 + 1) |cc| {
                        if ((rr != row or cc != col) and current[rr * cols + cc] == 2) adjacent = true;
                    }
                }
                const strike = input[tape + steps * cells + tick * cells + site];
                next[site] = if (adjacent or strike < input[5]) 2 else 1;
            }
        }
        var totals = [_]i64{ 0, 0, 0 };
        for (0..cells) |i| totals[@as(usize, next[i])] += 1;
        for (0..3) |state| putWord(out.ptr, 1 + 3 * tick + state, totals[state]);
        @memcpy(current[0..cells], next[0..cells]);
    }
    for (0..cells) |i| putWord(out.ptr, 1 + 3 * steps + i, @intCast(current[i]));
    return @intCast(bytes);
}
