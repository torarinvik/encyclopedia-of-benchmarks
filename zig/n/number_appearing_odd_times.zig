const MAX_LENGTH: usize = 4096;
const INVALID_RESULT: i64 = -2_147_483_649;

/// XOR-fold an int32 array to find its unique odd-frequency value.
export fn number_appearing_odd_times(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_LENGTH) return INVALID_RESULT;
    var result: i32 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < -2_147_483_648 or value > 2_147_483_647) return INVALID_RESULT;
        result ^= @as(i32, @intCast(value));
    }
    return result;
}
