const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const INT32_MIN_VALUE: i64 = -2_147_483_648;
const INT32_MAX_VALUE: i64 = 2_147_483_647;

export fn find_second_largest_element(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 10001) return INVALID_RESULT;
    const n = input[0];
    if (n < 2 or n > 10000 or length != @as(usize, @intCast(n)) + 1) return INVALID_RESULT;
    var largest: i64 = INT32_MIN_VALUE;
    for (0..@as(usize, @intCast(n))) |index| {
        const value = input[index + 1];
        if (value < INT32_MIN_VALUE or value > INT32_MAX_VALUE) return INVALID_RESULT;
        if (value > largest) largest = value;
    }
    var second: i64 = INT32_MIN_VALUE - 1;
    for (0..@as(usize, @intCast(n))) |index| {
        const value = input[index + 1];
        if (value < largest and value > second) second = value;
    }
    if (second == INT32_MIN_VALUE - 1) return INVALID_RESULT;
    return second;
}
