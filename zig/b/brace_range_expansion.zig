const Endpoint = struct {
    value: i64,
    letter: bool,
    width: usize,
    upper: bool,
};
const Plan = struct {
    open: usize,
    close: usize,
    start: i64,
    step: i64,
    letter: bool,
    pad: usize,
    count: usize,
};

fn endpoint(p: []const i64, begin: usize, end: usize) ?Endpoint {
    const n = end - begin;
    if (n == 1 and ((p[begin] >= 65 and p[begin] <= 90) or
                    (p[begin] >= 97 and p[begin] <= 122))) {
        return .{ .value = p[begin], .letter = true, .width = 1, .upper = p[begin] <= 90 };
    }
    if (n == 0 or n > 4) return null;
    var value: i64 = 0;
    for (p[begin..end]) |byte| {
        if (byte < 48 or byte > 57) return null;
        value = value * 10 + byte - 48;
    }
    return .{ .value = value, .letter = false, .width = n, .upper = false };
}

fn parseStep(p: []const i64, begin: usize, end: usize) ?i64 {
    var at = begin;
    var sign: i64 = 1;
    if (at < end and (p[at] == 43 or p[at] == 45)) {
        if (p[at] == 45) sign = -1;
        at += 1;
    }
    if (end - at == 0) return null;
    var value: i64 = 0;
    for (p[at..end]) |byte| {
        if (byte < 48 or byte > 57) return null;
        if (value < 10000) {
            value = value * 10 + byte - 48;
            if (value > 10000) value = 10000;
        }
    }
    if (value == 0) return null;
    return sign * value;
}

fn makePlan(p: []const i64) ?Plan {
    if (p.len == 0 or p.len > 64) return null;
    var open: ?usize = null;
    var close: ?usize = null;
    for (p, 0..) |byte, i| {
        if (byte < 32 or byte > 126) return null;
        if (byte == 123) {
            if (open != null) return null;
            open = i;
        } else if (byte == 125) {
            if (close != null) return null;
            close = i;
        }
    }
    const left = open orelse return null;
    const right = close orelse return null;
    if (right <= left or left + p.len - right - 1 > 32) return null;
    var separators: [2]usize = undefined;
    var separator_count: usize = 0;
    var i = left + 1;
    while (i + 1 < right) {
        if (p[i] == 46 and p[i+1] == 46) {
            if (separator_count == 2) return null;
            separators[separator_count] = i;
            separator_count += 1;
            i += 2;
        } else i += 1;
    }
    if (separator_count == 0) return null;
    const first_sep = separators[0];
    const second_sep = if (separator_count == 2) separators[1] else right;
    const a = endpoint(p, left+1, first_sep) orelse return null;
    const b = endpoint(p, first_sep+2, second_sep) orelse return null;
    if (a.letter != b.letter or (a.letter and a.upper != b.upper)) return null;
    const step: i64 = if (separator_count == 1)
        (if (a.value <= b.value) @as(i64, 1) else -1)
    else
        (parseStep(p, second_sep+2, right) orelse return null);
    if ((a.value < b.value and step < 0) or (a.value > b.value and step > 0)) return null;
    const count_i64: i64 = if (a.value == b.value) 1 else if (a.value < b.value)
        @divTrunc(b.value-a.value, step) + 1
    else
        @divTrunc(a.value-b.value, -step) + 1;
    if (count_i64 > 16) return null;
    const pad = if (!a.letter and (p[left+1] == 48 or p[first_sep+2] == 48))
        @max(a.width, b.width)
    else
        0;
    return .{ .open = left, .close = right, .start = a.value, .step = step,
        .letter = a.letter, .pad = pad, .count = @intCast(count_i64) };
}

export fn brace_range_expansion(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 65) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 1 or input[0] > 64 or length != @as(usize, @intCast(input[0])) + 1) return -1;
    const p = input[1..];
    const plan = makePlan(p) orelse return -1;
    var staged: [591]u8 = undefined;
    var out: usize = 0;
    var value = plan.start;
    const suffix_start = plan.close + 1;
    for (0..plan.count) |item| {
        if (item != 0) {
            staged[out] = 0;
            out += 1;
        }
        for (p[0..plan.open]) |byte| {
            staged[out] = @intCast(byte);
            out += 1;
        }
        if (plan.letter) {
            staged[out] = @intCast(value);
            out += 1;
        } else {
            var digits: [4]u8 = undefined;
            var used: usize = 0;
            var remaining: i64 = value;
            while (true) {
                digits[used] = @intCast(@mod(remaining, 10));
                used += 1;
                remaining = @divTrunc(remaining, 10);
                if (remaining == 0) break;
            }
            while (used < plan.pad) {
                staged[out] = 48;
                out += 1;
            }
            while (used > 0) {
                used -= 1;
                staged[out] = 48 + digits[used];
                out += 1;
            }
        }
        for (p[suffix_start..]) |byte| {
            staged[out] = @intCast(byte);
            out += 1;
        }
        value += plan.step;
    }
    if (output_opt == null or capacity < out) return -2;
    const output = output_opt.?[0..capacity];
    @memcpy(output[0..out], staged[0..out]);
    return @intCast(out);
}
