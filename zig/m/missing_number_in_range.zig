/// XOR a consecutive signed 32-bit range using portable zero-extended bit patterns.
const MAX_VALUES: usize = 1024;
const INVALID_RESULT: i64 = -2_147_483_649;

fn encodeI32(value: i64) u64 {
    return @intCast(if (value < 0) value + 4_294_967_296 else value);
}

export fn missing_number_in_range(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_VALUES) return INVALID_RESULT;
    var low = values[0];
    var high = low;
    for (0..length) |index| {
        const value = values[index];
        if (value < -2_147_483_648 or value > 2_147_483_647) return INVALID_RESULT;
        low = @min(low, value);
        high = @max(high, value);
    }
    if (high - low != length) return INVALID_RESULT;
    var seen: [MAX_VALUES + 1]bool = @splat(false);
    var actual: u64 = 0;
    for (0..length) |index| {
        const value = values[index];
        const slot: usize = @intCast(value - low);
        if (seen[slot]) return INVALID_RESULT;
        seen[slot] = true;
        actual ^= encodeI32(value);
    }
    var expected: u64 = 0;
    var value = low;
    while (value <= high) : (value += 1) expected ^= encodeI32(value);
    const result = expected ^ actual;
    if (result <= 2_147_483_647) return @intCast(result);
    return @as(i64, @intCast(result)) - 4_294_967_296;
}
