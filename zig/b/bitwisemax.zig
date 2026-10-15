const max_value: i64 = 2_147_483_647;

/// Select the larger signed-32-bit nonnegative value with a sign bit.
export fn bitwisemax(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const left = values[0];
    const right = values[1];
    if (left < 0 or left > max_value or right < 0 or right > max_value) return -1;
    const difference = left - right;
    const choose_right: i64 = @intCast(@as(u32, @truncate(difference)) >> 31);
    return left - choose_right * difference;
}
