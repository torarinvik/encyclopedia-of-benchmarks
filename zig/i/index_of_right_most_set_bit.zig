const INT32_MIN_VALUE: i64 = -2_147_483_648;
const INT32_MAX_VALUE: i64 = 2_147_483_647;

/// Zero-based trailing set-bit index using the Java magnitude behavior.
export fn index_of_right_most_set_bit(value: i64) i64 {
    if (value < INT32_MIN_VALUE or value > INT32_MAX_VALUE or value == 0) return -1;
    var magnitude: u64 = @intCast(if (value < 0) -value else value);
    var index: i64 = 0;
    while (magnitude & 1 == 0) {
        magnitude >>= 1;
        index += 1;
    }
    return index;
}
