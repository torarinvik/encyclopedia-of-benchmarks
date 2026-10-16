const MaxNodes = 481;
const Alphabet = 52;
const std = @import("std");
fn validChar(ch: i64) bool { return (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122); }
fn charIndex(ch: i64) usize { return if (ch <= 90) @intCast(ch - 65) else @intCast(ch - 97 + 26); }
fn visit(board: []const i64, rows: usize, cols: usize, pos: usize, node: usize,
         children: []u16, terminal: []i16,
         visited: *[36]bool, found: *[32]bool) void {
    visited[pos] = true;
    if (terminal[node] >= 0) found[@intCast(terminal[node])] = true;
    const row = @as(isize, @intCast(pos / cols)); const col = @as(isize, @intCast(pos % cols));
    for (0..3) |ri| for (0..3) |ci| {
        const dr: isize = @as(isize, @intCast(ri)) - 1; const dc: isize = @as(isize, @intCast(ci)) - 1;
        if (dr == 0 and dc == 0) continue;
        const nr = row + dr; const nc = col + dc;
        if (nr < 0 or nc < 0 or nr >= rows or nc >= cols) continue;
        const next: usize = @as(usize, @intCast(nr)) * cols + @as(usize, @intCast(nc));
        if (visited[next]) continue;
        const child = children[node * Alphabet + charIndex(board[next])];
        if (child > 0) visit(board, rows, cols, next, @intCast(child - 1), children, terminal, visited, found);
    };
    visited[pos] = false;
}
fn less(words: *[480]i64, lens: *[32]i32, a: usize, b: usize) bool {
    const n: usize = @intCast(@min(lens[a], lens[b]));
    for (0..n) |j| { const x = words[a * 15 + j]; const y = words[b * 15 + j]; if (x != y) return x < y; }
    return lens[a] < lens[b];
}
export fn word_boggle(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 551) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > 6 or values[1] < 1 or values[1] > 6) return -1;
    const rows: usize = @intCast(values[0]); const cols: usize = @intCast(values[1]); const cells = rows * cols; const dictAt = 2 + cells;
    if (length <= dictAt or values[dictAt] < 0 or values[dictAt] > 32) return -1;
    const count: usize = @intCast(values[dictAt]);
    for (values[2 .. 2 + cells]) |ch| if (!validChar(ch)) return -1;
    var words = @as([480]i64, @splat(0)); var lens = @as([32]i32, @splat(0)); var unique: usize = 0; var at = dictAt + 1;
    for (0..count) |_| {
        if (at >= length or values[at] < 1 or values[at] > 15) return -1;
        const n: usize = @intCast(values[at]); at += 1;
        if (length - at < n) return -1;
        var duplicate = false;
        for (0..unique) |w| if (lens[w] == n) {
            var same = true; for (0..n) |j| if (words[w * 15 + j] != values[at + j]) { same = false; };
            if (same) duplicate = true;
        };
        for (values[at .. at + n]) |ch| if (!validChar(ch)) return -1;
        if (!duplicate) { lens[unique] = @intCast(n); @memcpy(words[unique * 15 .. unique * 15 + n], values[at .. at + n]); unique += 1; }
        at += n;
    }
    if (at != length) return -1;
    const allocator = std.heap.page_allocator;
    const children = allocator.alloc(u16, MaxNodes * Alphabet) catch return -1;
    defer allocator.free(children);
    const terminal = allocator.alloc(i16, MaxNodes) catch return -1;
    defer allocator.free(terminal);
    @memset(children, 0); @memset(terminal, -1);
    var nodes: usize = 1;
    for (0..unique) |w| {
        var node: usize = 0;
        for (0..@as(usize, @intCast(lens[w]))) |j| {
            const slot = node * Alphabet + charIndex(words[w * 15 + j]);
            if (children[slot] == 0) { children[slot] = @intCast(nodes + 1); nodes += 1; }
            node = @intCast(children[slot] - 1);
        }
        terminal[node] = @intCast(w);
    }
    var found = @as([32]bool, @splat(false)); var visited = @as([36]bool, @splat(false));
    const board = values[2 .. 2 + cells];
    for (0..cells) |p| { const child = children[charIndex(board[p])]; if (child > 0) visit(board, rows, cols, p, @intCast(child - 1), children, terminal, &visited, &found); }
    var order = @as([32]usize, @splat(0)); var foundCount: usize = 0; var outputSize: usize = 0;
    for (0..unique) |w| if (found[w]) { order[foundCount] = w; foundCount += 1; outputSize += @as(usize, @intCast(lens[w])) + 1; };
    if (foundCount > 1) for (1..foundCount) |i| { const value = order[i]; var j = i; while (j > 0 and less(&words, &lens, value, order[j - 1])) : (j -= 1) { order[j] = order[j - 1]; } order[j] = value; };
    if (capacity < outputSize or (output == null and outputSize > 0)) return -2;
    var pos: usize = 0;
    for (0..foundCount) |k| { const w = order[k]; for (0..@as(usize, @intCast(lens[w]))) |j| { output.?[pos] = @intCast(words[w * 15 + j]); pos += 1; } output.?[pos] = 0; pos += 1; }
    return @intCast(outputSize);
}
