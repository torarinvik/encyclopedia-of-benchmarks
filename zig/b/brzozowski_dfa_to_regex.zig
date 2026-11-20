const std = @import("std");
const MAX_STATES: usize = 3;
const MAX_TEXT: usize = 512;
const Text = [MAX_TEXT]u8;

fn textSlice(text: *const Text) []const u8 {
    return text[0 .. std.mem.indexOfScalar(u8, text, 0) orelse MAX_TEXT];
}

fn textFrom(bytes: []const u8) ?Text {
    if (bytes.len >= MAX_TEXT) return null;
    var result: Text = @splat(0);
    @memcpy(result[0..bytes.len], bytes);
    return result;
}

fn regexUnion(left: *const Text, right: *const Text) ?Text {
    const a = textSlice(left);
    const b = textSlice(right);
    if (std.mem.eql(u8, a, "#")) return right.*;
    if (std.mem.eql(u8, b, "#") or std.mem.eql(u8, a, b)) return left.*;
    const left_first = std.mem.order(u8, a, b) == .lt;
    const first = if (left_first) a else b;
    const second = if (left_first) b else a;
    var buffer: Text = @splat(0);
    var pos: usize = 0;
    buffer[pos] = '('; pos += 1;
    @memcpy(buffer[pos .. pos + first.len], first); pos += first.len;
    buffer[pos] = '|'; pos += 1;
    @memcpy(buffer[pos .. pos + second.len], second); pos += second.len;
    buffer[pos] = ')';
    return buffer;
}

fn regexConcat(left: *const Text, right: *const Text) ?Text {
    const a = textSlice(left);
    const b = textSlice(right);
    if (std.mem.eql(u8, a, "#") or std.mem.eql(u8, b, "#")) return textFrom("#");
    if (std.mem.eql(u8, a, "@")) return right.*;
    if (std.mem.eql(u8, b, "@")) return left.*;
    var buffer: Text = @splat(0);
    var pos: usize = 0;
    buffer[pos] = '('; pos += 1;
    @memcpy(buffer[pos .. pos + a.len], a); pos += a.len;
    buffer[pos] = '.'; pos += 1;
    @memcpy(buffer[pos .. pos + b.len], b); pos += b.len;
    buffer[pos] = ')';
    return buffer;
}

fn regexStar(value: *const Text) ?Text {
    const inner = textSlice(value);
    if (std.mem.eql(u8, inner, "#") or std.mem.eql(u8, inner, "@")) return textFrom("@");
    var buffer: Text = @splat(0);
    buffer[0] = '(';
    @memcpy(buffer[1 .. 1 + inner.len], inner);
    buffer[1 + inner.len] = ')';
    buffer[2 + inner.len] = '*';
    return buffer;
}

export fn brzozowski_dfa_to_regex(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > 10) return -1;
    const input = input_opt.?[0..length];
    const n64 = input[0];
    const start64 = input[1];
    const accepting = input[2];
    if (n64 < 1 or n64 > MAX_STATES or start64 < 0 or start64 >= n64
        or accepting < 0 or accepting >= (@as(i64, 1) << @as(u6, @intCast(n64)))
        or length != 3 + 2 * @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    const start: usize = @intCast(start64);
    var coefficient: [MAX_STATES][MAX_STATES]Text = undefined;
    var constant: [MAX_STATES]Text = undefined;
    for (0..n) |state| {
        constant[state] = textFrom(if ((accepting & (@as(i64, 1) << @as(u6, @intCast(state)))) != 0) "@" else "#").?;
        for (0..n) |target| coefficient[state][target] = textFrom("#").?;
        for (0..2) |symbol| {
            const next_value = input[3 + 2 * state + symbol];
            if (next_value < 0 or next_value >= n64) return -1;
            const next: usize = @intCast(next_value);
            const label = textFrom(if (symbol == 0) "0" else "1").?;
            const merged = regexUnion(&coefficient[state][next], &label) orelse return -1;
            coefficient[state][next] = merged;
        }
    }
    for (0..n) |pivot| {
        if (pivot == start) continue;
        const loop_expr = regexStar(&coefficient[pivot][pivot]) orelse return -1;
        const pivot_row = coefficient[pivot];
        const pivot_constant = constant[pivot];
        var pivot_column: [MAX_STATES]Text = undefined;
        for (0..n) |state| pivot_column[state] = coefficient[state][pivot];
        for (0..n) |source| {
            if (source == pivot) continue;
            const prefix = regexConcat(&pivot_column[source], &loop_expr) orelse return -1;
            for (0..n) |target| {
                if (target == pivot) continue;
                const through = regexConcat(&prefix, &pivot_row[target]) orelse return -1;
                const merged = regexUnion(&coefficient[source][target], &through) orelse return -1;
                coefficient[source][target] = merged;
            }
            const through_constant = regexConcat(&prefix, &pivot_constant) orelse return -1;
            constant[source] = regexUnion(&constant[source], &through_constant) orelse return -1;
        }
    }
    const loop_expr = regexStar(&coefficient[start][start]) orelse return -1;
    const answer = regexConcat(&loop_expr, &constant[start]) orelse return -1;
    const bytes = textSlice(&answer);
    if (bytes.len > 270) return -1;
    if (output_opt == null or capacity < bytes.len) return -2;
    @memcpy(output_opt.?[0..bytes.len], bytes);
    return @intCast(bytes.len);
}
