const MAX_INPUT_LENGTH: usize = 260;
const MAX_TEXT_LENGTH: usize = 256;
const MAX_KEY: usize = 256;

export fn skytale_cipher(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 1 or values[1] < 1 or values[1] > MAX_KEY or
        values[2] < 0 or values[2] > MAX_TEXT_LENGTH) return -1;
    const mode: usize = @intCast(values[0]);
    const key: usize = @intCast(values[1]);
    const n: usize = @intCast(values[2]);
    if (length != 3 + n) return -1;
    for (values[3..]) |value| { if (value < 0 or value > 127) return -1; }
    if (output == null or capacity < n) return -2;
    const result = output.?[0..n];

    if (mode == 0) {
        var out: usize = 0;
        for (0..key) |row| {
            var position = row;
            while (position < n) : (position += key) {
                result[out] = @intCast(values[3 + position]);
                out += 1;
            }
        }
    } else {
        var starts = [_]usize{0} ** MAX_KEY;
        var used = [_]usize{0} ** MAX_KEY;
        const base = n / key;
        const extra = n % key;
        for (1..key) |row| starts[row] = starts[row - 1] + base + @intFromBool(row - 1 < extra);
        for (0..n) |position| {
            const row = position % key;
            result[position] = @intCast(values[3 + starts[row] + used[row]]);
            used[row] += 1;
        }
    }
    return @intCast(n);
}
