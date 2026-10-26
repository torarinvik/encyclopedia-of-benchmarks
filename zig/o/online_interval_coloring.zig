// Clean-room bounded Kierstead-Trotter online interval coloring profile.
const max_n: usize = 64;
const max_input: usize = 129;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn levelFits(left: [max_n]i64, right: [max_n]i64, levels: [max_n]usize,
    last: usize, candidate: usize) bool {
    for (0..last + 1) |anchor| {
        const point = left[anchor];
        var overlap: usize = 0;
        for (0..last + 1) |item| {
            if ((item == last or levels[item] <= candidate) and left[item] <= point and point <= right[item]) overlap += 1;
        }
        if (overlap > candidate) return false;
    }
    return true;
}

export fn online_interval_coloring(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input) return -1;
    const input = input_opt.?;
    const count64 = input[0];
    if (count64 < 0 or count64 > 64 or length != 1 + 2 * @as(usize, @intCast(count64))) return -1;
    const n: usize = @intCast(count64);
    var left: [max_n]i64 = [_]i64{0} ** max_n;
    var right: [max_n]i64 = [_]i64{0} ** max_n;
    for (0..n) |i| {
        left[i] = input[1 + 2 * i]; right[i] = input[2 + 2 * i];
        if (left[i] < -1000 or left[i] > 1000 or right[i] < -1000 or right[i] > 1000 or left[i] > right[i]) return -1;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var levels: [max_n]usize = [_]usize{0} ** max_n;
    var local: [max_n]usize = [_]usize{0} ** max_n;
    var colors: [max_n]usize = [_]usize{0} ** max_n;
    for (0..n) |i| {
        var level: usize = 1;
        while (!levelFits(left, right, levels, i, level)) {
            level += 1;
            if (level > i + 1) return -1;
        }
        levels[i] = level;
        var used = [_]bool{false} ** 3;
        for (0..i) |j| {
            if (levels[j] == level and left[j] <= right[i] and left[i] <= right[j] and local[j] < 3) used[local[j]] = true;
        }
        var color: usize = 0;
        while (color < 3 and used[color]) : (color += 1) {}
        if (color == 3) return -1;
        local[i] = color; colors[i] = 3 * (level - 1) + color;
    }
    for (0..n) |i| storeI64LE(output, 8 * i, @intCast(colors[i]));
    return @intCast(output_bytes);
}
