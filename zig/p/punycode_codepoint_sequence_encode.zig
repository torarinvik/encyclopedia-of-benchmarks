const MAX_POINTS: usize = 32;
const MAX_WORDS: usize = 34;
const MAX_OUTPUT: usize = 320;

fn adaptBias(initial_delta: i64, point_count: i64, first_time: bool) i64 {
    var delta = initial_delta / (if (first_time) @as(i64, 700) else 2);
    delta += @divTrunc(delta, point_count);
    var k: i64 = 0;
    while (delta > ((36 - 1) * 26) / 2) {
        delta = @divTrunc(delta, 35);
        k += 36;
    }
    return k + @divTrunc(36 * delta, delta + 38);
}

fn digitByte(digit: i64) u8 {
    return if (digit < 26) @intCast('a' + digit) else @intCast('0' + digit - 26);
}

fn scalar(value: i64) bool {
    return value >= 0 and value <= 0x10ffff and !(value >= 0xd800 and value <= 0xdfff);
}

fn encode(points: []const i64, staged: *[MAX_OUTPUT]u8) usize {
    var basic_count: usize = 0;
    for (points) |point| {
        if (point < 0x80) {
            staged[basic_count] = @intCast(point);
            basic_count += 1;
        }
    }
    var written = basic_count;
    if (basic_count != 0) {
        staged[written] = '-';
        written += 1;
    }
    var n: i64 = 128;
    var delta: i64 = 0;
    var bias: i64 = 72;
    var handled = basic_count;
    while (handled < points.len) {
        var minimum: i64 = 0x110000;
        for (points) |point| {
            if (point >= n and point < minimum) minimum = point;
        }
        delta += (minimum - n) * @as(i64, @intCast(handled + 1));
        n = minimum;
        for (points) |point| {
            if (point < n) delta += 1;
            if (point == n) {
                var q = delta;
                var k: i64 = 36;
                while (true) : (k += 36) {
                    const threshold: i64 = if (k <= bias) 1 else if (k >= bias + 26) 26 else k - bias;
                    if (q < threshold) {
                        staged[written] = digitByte(q);
                        written += 1;
                        break;
                    }
                    staged[written] = digitByte(threshold + @mod(q - threshold, 36 - threshold));
                    written += 1;
                    q = @divTrunc(q - threshold, 36 - threshold);
                }
                bias = adaptBias(delta, @as(i64, @intCast(handled + 1)), handled == basic_count);
                delta = 0;
                handled += 1;
            }
        }
        delta += 1;
        n += 1;
    }
    return written;
}

pub export fn punycode_codepoint_sequence_encode(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > MAX_WORDS) return -1;
    const count_word = values[0];
    if (count_word < 0 or count_word > @as(i64, @intCast(MAX_POINTS)) or
        length != @as(usize, @intCast(count_word)) + 1) return -1;
    const count: usize = @intCast(count_word);
    var staged: [MAX_OUTPUT]u8 = undefined;
    for (0..count) |index| {
        if (!scalar(values[index + 1])) return -1;
    }
    const written = encode(values[1 .. count + 1], &staged);
    if (written > MAX_OUTPUT) return -1;
    if (written != 0) {
        const destination = output orelse return -2;
        if (capacity < written) return -2;
        for (0..written) |index| destination[index] = staged[index];
    }
    return @intCast(written);
}
