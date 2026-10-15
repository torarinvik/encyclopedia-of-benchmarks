const MAX_PATTERNS: usize = 16;
const MAX_PATTERN_LENGTH: usize = 32;
const MAX_TEXT_LENGTH: usize = 256;
const MAX_NODES: usize = 1 + MAX_PATTERNS * MAX_PATTERN_LENGTH;
const ALPHABET: usize = 128;

export fn aho_corasick(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > MAX_PATTERNS or values[1] < 0 or values[1] > MAX_TEXT_LENGTH) return -1;
    const pattern_count: usize = @intCast(values[0]);
    if (length < 2 + pattern_count) return -1;
    var starts: [MAX_PATTERNS]usize = undefined;
    var text_start: usize = 2 + pattern_count;
    for (0..pattern_count) |p| {
        if (values[2 + p] < 1 or values[2 + p] > MAX_PATTERN_LENGTH) return -1;
        const size: usize = @intCast(values[2 + p]);
        if (text_start + size > length) return -1;
        starts[p] = text_start;
        for (values[text_start .. text_start + size]) |ch| if (ch < 1 or ch > 127) return -1;
        for (0..p) |q| {
            if (values[2 + q] != @as(i64, @intCast(size))) continue;
            if (std.mem.eql(i64, values[starts[q] .. starts[q] + size], values[starts[p] .. starts[p] + size])) return -1;
        }
        text_start += size;
    }
    const text_length: usize = @intCast(values[1]);
    if (text_start + text_length != length) return -1;
    for (values[text_start..]) |ch| if (ch < 1 or ch > 127) return -1;
    const output_size = pattern_count * 8;
    if (output_capacity < output_size or output == null) return -2;

    var next: [MAX_NODES][ALPHABET]i32 = undefined;
    var failure: [MAX_NODES]usize = @splat(0);
    var terminal: [MAX_NODES]i32 = @splat(-1);
    var queue: [MAX_NODES]usize = undefined;
    for (&next) |*row| @memset(row, -1);
    var nodes: usize = 1;
    for (0..pattern_count) |p| {
        var state: usize = 0;
        for (values[starts[p] .. starts[p] + @as(usize, @intCast(values[2 + p]))]) |raw| {
            const ch: usize = @intCast(raw);
            if (next[state][ch] == -1) {
                next[state][ch] = @intCast(nodes);
                nodes += 1;
            }
            state = @intCast(next[state][ch]);
        }
        terminal[state] = @intCast(p);
    }
    var head: usize = 0;
    var tail: usize = 0;
    for (1..ALPHABET) |ch| {
        if (next[0][ch] != -1) { queue[tail] = @intCast(next[0][ch]); tail += 1; }
    }
    while (head < tail) {
        const state = queue[head]; head += 1;
        for (1..ALPHABET) |ch| {
            const child = next[state][ch];
            if (child == -1) continue;
            var suffix = failure[state];
            while (suffix != 0 and next[suffix][ch] == -1) suffix = failure[suffix];
            if (next[suffix][ch] != -1) suffix = @intCast(next[suffix][ch]);
            failure[@intCast(child)] = suffix;
            queue[tail] = @intCast(child);
            tail += 1;
        }
    }
    var counts: [MAX_PATTERNS]i64 = @splat(0);
    var state: usize = 0;
    for (values[text_start..]) |raw| {
        const ch: usize = @intCast(raw);
        while (state != 0 and next[state][ch] == -1) state = failure[state];
        if (next[state][ch] != -1) state = @intCast(next[state][ch]);
        var matched = state;
        while (matched != 0) : (matched = failure[matched]) {
            if (terminal[matched] >= 0) counts[@intCast(terminal[matched])] += 1;
        }
    }
    const out = output.?;
    for (0..pattern_count) |p| {
        var value: u64 = @intCast(counts[p]);
        for (0..8) |b| {
            out[p * 8 + b] = @truncate(value);
            value >>= 8;
        }
    }
    return @intCast(output_size);
}

const std = @import("std");
