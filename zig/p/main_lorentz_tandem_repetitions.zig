const N: usize = 24;
const MAX_REPETITIONS: usize = N * N / 4;
const INPUT_MAX: usize = N + 1;
const Z_MAX: usize = 2 * N + 1;
const Marked = [N][N + 1]bool;

fn zValues(text: *const [Z_MAX]i64, length: usize, z: *[Z_MAX]usize) void {
    for (0..Z_MAX) |index| z[index] = 0;
    var left: usize = 0;
    var right: usize = 0;
    var has_box = false;
    var i: usize = 1;
    while (i < length) : (i += 1) {
        if (has_box and i <= right) z[i] = @min(right - i + 1, z[i - left]);
        while (i + z[i] < length and text[z[i]] == text[i + z[i]]) z[i] += 1;
        if (!has_box or i + z[i] - 1 > right) {
            left = i;
            right = i + z[i] - 1;
            has_box = true;
        }
    }
}

fn zAt(z: *const [Z_MAX]usize, length: usize, index: usize) usize {
    return if (index < length) z[index] else 0;
}

fn divide(symbols: *const [N]i64, offset: usize, length: usize, marked: *Marked) void {
    if (length <= 1) return;
    const left_size = length / 2;
    const right_size = length - left_size;
    const middle = offset + left_size;
    var buffer: [Z_MAX]i64 = @splat(0);
    var z: [Z_MAX]usize = @splat(0);
    var before: [N]usize = @splat(0);
    var after: [N]usize = @splat(0);

    divide(symbols, offset, left_size, marked);
    divide(symbols, middle, right_size, marked);

    for (0..left_size) |i| buffer[i] = symbols[middle - 1 - i];
    zValues(&buffer, left_size, &z);
    for (0..left_size) |center| before[center] = zAt(&z, left_size, left_size - center);

    var used: usize = 0;
    for (0..right_size) |i| { buffer[used] = symbols[middle + i]; used += 1; }
    buffer[used] = -1;
    used += 1;
    for (0..left_size) |i| { buffer[used] = symbols[offset + i]; used += 1; }
    zValues(&buffer, used, &z);
    for (0..left_size) |center| after[center] = zAt(&z, used, right_size + 1 + center);

    for (0..left_size) |i| buffer[i] = symbols[middle - 1 - i];
    used = left_size;
    buffer[used] = -1;
    used += 1;
    for (0..right_size) |i| { buffer[used] = symbols[offset + length - 1 - i]; used += 1; }
    zValues(&buffer, used, &z);
    for (0..right_size) |d| before[left_size + d] = zAt(&z, used, left_size + 1 + right_size - 1 - d);

    for (0..right_size) |i| buffer[i] = symbols[middle + i];
    zValues(&buffer, right_size, &z);
    for (0..right_size) |d| after[left_size + d] = zAt(&z, right_size, d + 1);

    for (0..length) |center| {
        const left_biased = center < left_size;
        const half = if (left_biased) left_size - center else center - left_size + 1;
        if (before[center] + after[center] < half) continue;
        const low = @max(1, if (half > after[center]) half - after[center] else 0);
        const high = @min(half, before[center]);
        var first_half = low;
        while (first_half <= high) : (first_half += 1) {
            if (left_biased and first_half == half) continue;
            const start = if (left_biased) center - first_half else center - half - first_half + 1;
            marked[offset + start][half] = true;
        }
    }
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn main_lorentz_tandem_repetitions(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > INPUT_MAX) return -1;
    const input = input_opt.?;
    const nr = input[0];
    if (nr < 0 or nr > @as(i64, @intCast(N)) or length != @as(usize, @intCast(nr)) + 1) return -1;
    const n: usize = @intCast(nr);
    var symbols: [N]i64 = @splat(0);
    for (0..n) |i| {
        symbols[i] = input[i + 1];
        if (symbols[i] < 0 or symbols[i] > 255) return -1;
    }

    var marked: Marked = undefined;
    for (0..N) |row| for (0..N + 1) |column| { marked[row][column] = false; };
    divide(&symbols, 0, n, &marked);
    var codes: [MAX_REPETITIONS]i64 = @splat(0);
    var count: usize = 0;
    for (0..n) |start| {
        var half: usize = 1;
        while (half <= n / 2) : (half += 1) {
            if (start + 2 * half <= n and marked[start][half]) {
                codes[count] = @intCast(start * 32 + half);
                count += 1;
            }
        }
    }
    const required = 8 * (count + 1);
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    storeLe(output, 0, @intCast(count));
    for (0..count) |i| storeLe(output, 8 * (i + 1), codes[i]);
    return @intCast(required);
}
