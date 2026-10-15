const MAX_INTERVALS: usize = 64;
const SCALE: u64 = 1_000_000;

fn putByte(output: []u8, output_length: *usize, value: u8) bool {
    if (output_length.* >= output.len) return false;
    output[output_length.*] = value;
    output_length.* += 1;
    return true;
}

fn putText(output: []u8, output_length: *usize, text: []const u8) bool {
    for (text) |byte| {
        if (!putByte(output, output_length, byte)) return false;
    }
    return true;
}

fn putUint(output: []u8, output_length: *usize, value: u64) bool {
    var digits: [20]u8 = undefined;
    var count: usize = 0;
    var remaining = value;
    while (true) {
        digits[count] = @intCast(48 + remaining % 10);
        count += 1;
        remaining /= 10;
        if (remaining == 0) break;
    }
    while (count > 0) {
        count -= 1;
        if (!putByte(output, output_length, digits[count])) return false;
    }
    return true;
}

fn putFixed(output: []u8, output_length: *usize, ticks: u64) bool {
    if (!putUint(output, output_length, ticks / SCALE) or !putByte(output, output_length, '.')) return false;
    var fraction = ticks % SCALE;
    var divisor: u64 = 100_000;
    while (divisor > 0) : (divisor /= 10) {
        if (!putByte(output, output_length, @intCast(48 + fraction / divisor % 10))) return false;
        fraction %= divisor;
    }
    return true;
}

export fn cantor_set(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > values[1] or values[1] > 100_000 or values[2] < 0 or values[2] > 6) return -1;
    if (output == null) return -2;
    const result = output.?[0..output_capacity];

    const start: u64 = @intCast(values[0]);
    const span: u64 = @intCast(values[1] - values[0]);
    const levels: usize = @intCast(values[2]);
    var positions: [MAX_INTERVALS]u64 = @splat(0);
    var next: [MAX_INTERVALS]u64 = @splat(0);
    var interval_count: usize = 1;
    var denominator: u64 = 1;
    var output_length: usize = 0;

    for (0..levels + 1) |level| {
        if (!putText(result, &output_length, "Level ") or
            !putUint(result, &output_length, @intCast(level)) or
            !putByte(result, &output_length, '\t')) return -2;
        for (0..interval_count) |index| {
            const left_numerator = start * denominator + span * positions[index];
            const right_numerator = start * denominator + span * (positions[index] + 1);
            const left = (left_numerator * SCALE + denominator / 2) / denominator;
            const right = (right_numerator * SCALE + denominator / 2) / denominator;
            if (!putText(result, &output_length, "\t[") or
                !putFixed(result, &output_length, left) or
                !putText(result, &output_length, "] -- [") or
                !putFixed(result, &output_length, right) or
                !putByte(result, &output_length, ']')) return -2;
        }
        if (!putByte(result, &output_length, '\n')) return -2;
        if (level < levels) {
            if (!putByte(result, &output_length, '\n')) return -2;
            for (0..interval_count) |index| {
                next[2 * index] = positions[index] * 3;
                next[2 * index + 1] = positions[index] * 3 + 2;
            }
            interval_count *= 2;
            for (0..interval_count) |index| positions[index] = next[index];
            denominator *= 3;
        }
    }
    if (output_length >= result.len) return -2;
    result[output_length] = 0;
    return @intCast(output_length + 1);
}
