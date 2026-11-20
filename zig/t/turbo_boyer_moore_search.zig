const MAX_TEXT: usize = 255;
const MAX_PATTERN: usize = 64;
const MAX_FRAME: usize = 322;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn goodSuffix(pattern: [*c]const i64, length: usize, shifts: *[MAX_PATTERN]usize) void {
    var suffix: [MAX_PATTERN]usize = @splat(0);
    suffix[length - 1] = length;
    var g: isize = @as(isize, @intCast(length)) - 1;
    var f: isize = 0;
    var index: isize = @as(isize, @intCast(length)) - 2;
    while (index >= 0) : (index -= 1) {
        const probe: usize = @intCast(index + @as(isize, @intCast(length)) - 1 - f);
        if (index > g and suffix[probe] < @as(usize, @intCast(index - g))) {
            suffix[@intCast(index)] = suffix[probe];
        } else {
            if (index < g) g = index;
            f = index;
            while (g >= 0 and pattern[@intCast(g)] == pattern[@intCast(g + @as(isize, @intCast(length)) - 1 - f)]) : (g -= 1) {}
            suffix[@intCast(index)] = @intCast(f - g);
        }
    }
    for (0..length) |i| shifts[i] = length;
    var border: usize = 0;
    index = @as(isize, @intCast(length)) - 1;
    while (index >= 0) : (index -= 1) {
        const i: usize = @intCast(index);
        if (suffix[i] == i + 1) {
            while (border < length - 1 - i) : (border += 1) {
                if (shifts[border] == length) shifts[border] = length - 1 - i;
            }
        }
    }
    for (0..length - 1) |i| shifts[length - 1 - suffix[i]] = length - 1 - i;
}

export fn turbo_boyer_moore_search(input: [*c]const i64, length: usize,
        output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_FRAME) return -1;
    if (input[0] < 0 or input[0] > MAX_TEXT or input[1] < 1 or input[1] > MAX_PATTERN) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;
    for (0..n + m) |i| if (input[2 + i] < 0 or input[2 + i] > 127) return -1;

    var positions: [MAX_TEXT]i64 = @splat(0);
    var match_count: usize = 0;
    if (m <= n) {
        var bad: [128]usize = @splat(m);
        var good: [MAX_PATTERN]usize = @splat(0);
        var gs: [MAX_PATTERN]usize = @splat(0);
        for (0..m - 1) |i| bad[@intCast(input[2 + n + i])] = m - i - 1;
        goodSuffix(input + 2 + n, m, &gs);
        for (0..m) |i| good[i] = gs[i];

        var alignment: usize = 0;
        var remembered: usize = 0;
        var shift: usize = m;
        while (alignment <= n - m) {
            var i: isize = @as(isize, @intCast(m)) - 1;
            while (i >= 0 and input[2 + n + @as(usize, @intCast(i))] == input[2 + alignment + @as(usize, @intCast(i))]) {
                i -= 1;
                if (remembered != 0 and i == @as(isize, @intCast(m)) - 1 - @as(isize, @intCast(shift)))
                    i -= @intCast(remembered);
            }
            if (i < 0) {
                positions[match_count] = @intCast(alignment);
                match_count += 1;
                shift = good[0];
                remembered = m - shift;
            } else {
                const ui: usize = @intCast(i);
                const matched = m - 1 - ui;
                const turbo_shift: isize = @as(isize, @intCast(remembered)) - @as(isize, @intCast(matched));
                const bad_shift: isize = @as(isize, @intCast(bad[@intCast(input[2 + alignment + ui])])) -
                    @as(isize, @intCast(m)) + 1 + i;
                const gs_value = good[ui];
                var chosen = @max(turbo_shift, bad_shift);
                chosen = @max(chosen, @as(isize, @intCast(gs_value)));
                shift = @intCast(chosen);
                if (shift == gs_value) {
                    remembered = @min(m - shift, matched);
                } else {
                    if (turbo_shift < bad_shift) shift = @max(shift, remembered + 1);
                    remembered = 0;
                }
            }
            alignment += shift;
        }
    }
    const output_bytes = match_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..match_count) |i| storeI64Le(output, i * 8, positions[i]);
    return @intCast(output_bytes);
}
