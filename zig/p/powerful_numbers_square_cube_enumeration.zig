const MAX_INPUT_WORDS: usize = 2;
const MAX_LIMIT: i64 = 100;

fn isSquarefree(value: i64) bool {
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@mod(value, divisor * divisor) == 0) return false;
    }
    return true;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn powerful_numbers_square_cube_enumeration(raw: ?[*]const i64,
    length: usize, output: ?[*]u8, capacity: usize) i64 {
    const input = raw orelse return -1;
    if (length < 1 or length > MAX_INPUT_WORDS or length != 1) return -1;
    const limit = input[0];
    if (limit < 1 or limit > MAX_LIMIT) return -1;

    var values = [_]i64{0} ** 14;
    var count: usize = 0;
    var b: i64 = 1;
    while (b * b * b <= limit) : (b += 1) {
        if (!isSquarefree(b)) continue;
        const cube = b * b * b;
        var a: i64 = 1;
        while (a * a * cube <= limit) : (a += 1) {
            values[count] = a * a * cube;
            count += 1;
        }
    }
    for (1..count) |index| {
        const value = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > value) : (position -= 1) {
            values[position] = values[position - 1];
        }
        values[position] = value;
    }

    const output_bytes = (count + 1) * 8;
    const destination = output orelse return -2;
    if (capacity < output_bytes) return -2;
    storeI64Le(destination, 0, @intCast(count));
    for (0..count) |index| storeI64Le(destination, (index + 1) * 8, values[index]);
    return @intCast(output_bytes);
}
