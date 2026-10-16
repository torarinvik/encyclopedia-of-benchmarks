const MAX = 8;
fn search(grid: *[64]i64, rows: usize, cols: usize, words: *[8][8]i64,
    lengths: *[8]usize, remaining: *[8]usize, count: usize) bool {
    const total = rows * cols;
    var start: usize = 0;
    while (start < total and grid[start] != 0) : (start += 1) {}
    if (start == total) return true;
    const row = start / cols;
    const col = start % cols;
    var current = remaining.*;
    var current_count = count;
    for (0..count) |wi| {
        const word_index = remaining[wi];
        const word_length = lengths[word_index];
        for (0..2) |direction| {
            const vertical = direction == 0;
            if ((vertical and row + word_length > rows) or (!vertical and col + word_length > cols)) continue;
            var valid = true;
            for (0..word_length) |i| {
                const cell = if (vertical) (row + i) * cols + col else row * cols + col + i;
                if (grid[cell] != 0) valid = false;
            }
            if (!valid) continue;
            for (0..word_length) |i| {
                const cell = if (vertical) (row + i) * cols + col else row * cols + col + i;
                grid[cell] = words[word_index][i];
            }
            var next: [8]usize = undefined;
            var next_count: usize = 0;
            var removed: usize = 0;
            for (0..current_count) |i| {
                if (current[i] == word_index) { removed = i; } else { next[next_count] = current[i]; next_count += 1; }
            }
            for (removed + 1..current_count) |i| current[i - 1] = current[i];
            current_count -= 1;
            if (search(grid, rows, cols, words, lengths, &next, next_count)) return true;
            for (0..word_length) |i| {
                const cell = if (vertical) (row + i) * cols + col else row * cols + col + i;
                grid[cell] = 0;
            }
            current[current_count] = word_index;
            current_count += 1;
        }
    }
    return false;
}

export fn crossword_solver(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const values = input.?;
    const rv = values[0]; const cv = values[1]; const nv = values[2];
    if (rv < 1 or rv > 8 or cv < 1 or cv > 8 or nv < 0 or nv > 8) return -1;
    const rows: usize = @intCast(rv); const cols: usize = @intCast(cv); const count: usize = @intCast(nv);
    if (length < 3 + rows * cols) return -1;
    var grid: [64]i64 = @splat(0);
    for (0..rows * cols) |i| { const v = values[3 + i]; if (v != 0 and v != -1 and (v < 65 or v > 90)) return -1; grid[i] = v; }
    var words: [8][8]i64 = @splat(@splat(0)); var lengths: [8]usize = @splat(0);
    var pos: usize = 3 + rows * cols;
    for (0..count) |w| {
        if (pos >= length or values[pos] < 1 or values[pos] > 8) return -1;
        lengths[w] = @intCast(values[pos]); pos += 1;
        if (lengths[w] > length - pos) return -1;
        for (0..lengths[w]) |i| { const v = values[pos]; if (v < 65 or v > 90) return -1; words[w][i] = v; pos += 1; }
        for (0..w) |prior| { if (lengths[prior] == lengths[w] and std.mem.eql(i64, words[prior][0..lengths[w]], words[w][0..lengths[w]])) return -1; }
    }
    if (pos != length) return -1;
    var remaining: [8]usize = @splat(0); for (0..count) |i| remaining[i] = i;
    const solved = search(&grid, rows, cols, &words, &lengths, &remaining, count);
    const required = (1 + rows * cols) * 8;
    if (output == null or capacity < required) return -2;
    const out = output.?;
    for (0..1 + rows * cols) |i| {
        const value: i64 = if (i == 0) (if (solved) 1 else 0) else grid[i - 1];
        const bits: u64 = @bitCast(value);
        for (0..8) |b| out[i * 8 + b] = @truncate(bits >> @intCast(b * 8));
    }
    return @intCast(required);
}
const std = @import("std");
