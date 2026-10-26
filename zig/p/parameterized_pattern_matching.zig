const MAX_TEXT: usize = 24;
const MAX_PATTERN: usize = 8;
const ALPHABET: usize = 16;
const MAX_OUTPUT_BYTES: usize = 200;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn predecessor_code(symbols: []const i64, code: []i64) void {
    var last: [ALPHABET]i64 = @splat(-1);
    for (symbols, 0..) |symbol, index| {
        const slot: usize = @intCast(symbol);
        code[index] = if (last[slot] < 0) 0 else @as(i64, @intCast(index)) - last[slot];
        last[slot] = @intCast(index);
    }
}

export fn parameterized_pattern_matching(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > 2 + MAX_TEXT + MAX_PATTERN) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, MAX_TEXT) or
        input[1] < 1 or input[1] > @as(i64, MAX_PATTERN)) return -1;
    const text_length: usize = @intCast(input[0]);
    const pattern_length: usize = @intCast(input[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (2..length) |index| if (input[index] < 0 or input[index] >= @as(i64, ALPHABET)) return -1;

    const text = input[2 .. 2 + text_length];
    const pattern = input[2 + text_length .. length];
    var pattern_code: [MAX_PATTERN]i64 = @splat(0);
    predecessor_code(pattern, pattern_code[0..pattern_length]);
    var matches: [MAX_TEXT]usize = @splat(0);
    var match_count: usize = 0;
    if (pattern_length <= text_length) {
        for (0..text_length - pattern_length + 1) |start| {
            var window_code: [MAX_PATTERN]i64 = @splat(0);
            predecessor_code(text[start .. start + pattern_length], window_code[0..pattern_length]);
            if (std.mem.eql(i64, pattern_code[0..pattern_length], window_code[0..pattern_length])) {
                matches[match_count] = start;
                match_count += 1;
            }
        }
    }
    const output_bytes = 8 * (match_count + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    store_i64_le(&staged, 0, @intCast(match_count));
    for (0..match_count) |index| store_i64_le(&staged, 8 * (index + 1), @intCast(matches[index]));
    for (0..output_bytes) |index| output[index] = staged[index];
    return @intCast(output_bytes);
}

const std = @import("std");
