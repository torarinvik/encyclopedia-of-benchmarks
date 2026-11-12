const MAX_TEXT_LENGTH: usize = 64;
const MAX_PATTERN_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 99;

const Factorization = struct { critical: i64, period: i64 };

fn maximalSuffix(pattern: [*]const i64, length: usize, reverse_order: bool) Factorization {
    var maximal: i64 = -1;
    var candidate: i64 = 0;
    var offset: i64 = 1;
    var period: i64 = 1;
    const signed_length: i64 = @intCast(length);
    while (candidate + offset < signed_length) {
        const a = pattern[@intCast(candidate + offset)];
        const b = pattern[@intCast(maximal + offset)];
        const precedes = if (reverse_order) a > b else a < b;
        if (precedes) {
            candidate += offset;
            offset = 1;
            period = candidate - maximal;
        } else if (a == b) {
            if (offset != period) {
                offset += 1;
            } else {
                candidate += period;
                offset = 1;
            }
        } else {
            maximal = candidate;
            candidate = maximal + 1;
            offset = 1;
            period = 1;
        }
    }
    return .{ .critical = maximal, .period = period };
}

fn twoWay(
    text: [*]const i64,
    text_length: usize,
    pattern: [*]const i64,
    pattern_length: usize,
    matches: [*]i64,
) usize {
    var match_count: usize = 0;
    if (pattern_length == 0) {
        for (0..(text_length + 1)) |i| {
            matches[match_count] = @intCast(i);
            match_count += 1;
        }
        return match_count;
    }
    if (pattern_length > text_length) return 0;

    const first = maximalSuffix(pattern, pattern_length, false);
    const second = maximalSuffix(pattern, pattern_length, true);
    const chosen = if (first.critical > second.critical) first else second;
    const critical = chosen.critical;
    const period = chosen.period;
    const m: i64 = @intCast(pattern_length);
    var periodic = period + critical + 1 <= m;
    var part: i64 = 0;
    while (periodic and part <= critical) : (part += 1) {
        if (pattern[@intCast(part)] != pattern[@intCast(part + period)]) periodic = false;
    }
    const shift = if (periodic) period else @max(critical, m - critical - 1) + 1;
    var memory: i64 = -1;
    var start: usize = 0;
    while (start <= text_length - pattern_length) {
        var index: i64 = if (periodic) @max(critical, memory) + 1 else critical + 1;
        while (index < m
            and pattern[@intCast(index)] == text[start + @as(usize, @intCast(index))]) : (index += 1) {}
        if (index >= m) {
            index = critical;
            while (index > memory
                and pattern[@intCast(index)] == text[start + @as(usize, @intCast(index))]) : (index -= 1) {}
            if (index <= memory) {
                matches[match_count] = @intCast(start);
                match_count += 1;
            }
            start += @intCast(shift);
            memory = if (periodic) m - period - 1 else -1;
        } else {
            start += @intCast(index - critical);
            memory = -1;
        }
    }
    return match_count;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn crochemore_perrin_two_way(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 0 or values[0] > @as(i64, MAX_TEXT_LENGTH)
        or values[1] < 0 or values[1] > @as(i64, MAX_PATTERN_LENGTH)) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    var text: [MAX_TEXT_LENGTH]i64 = @splat(0);
    var pattern: [MAX_PATTERN_LENGTH]i64 = @splat(0);
    for (0..text_length) |i| {
        const value = values[2 + i];
        if (value < 0 or value > 255) return -1;
        text[i] = value;
    }
    for (0..pattern_length) |i| {
        const value = values[2 + text_length + i];
        if (value < 0 or value > 255) return -1;
        pattern[i] = value;
    }
    var matches: [MAX_TEXT_LENGTH + 1]i64 = @splat(0);
    const match_count = twoWay(&text[0], text_length, &pattern[0], pattern_length, &matches[0]);
    const output_bytes = match_count * 8;
    if (output == null or capacity < output_bytes) return -2;
    for (0..match_count) |i| putI64Le(output, i * 8, matches[i]);
    return @intCast(output_bytes);
}
