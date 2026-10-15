const MAX_ITEMS: usize = 256;
const MAX_SAFE_INTEGER: i64 = 9_007_199_254_740_991;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

fn gcdNonnegative(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @mod(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

export fn greatest_common_factor(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_ITEMS + 1) return INVALID_RESULT;
    const values = input.?[0..length];
    const count = values[0];
    if (count < 1 or count > MAX_ITEMS or length != @as(usize, @intCast(count)) + 1) return INVALID_RESULT;
    var result = values[1];
    if (result < 0 or result > MAX_SAFE_INTEGER) return INVALID_RESULT;
    for (values[2..]) |value| {
        if (value < 0 or value > MAX_SAFE_INTEGER) return INVALID_RESULT;
        result = gcdNonnegative(result, value);
    }
    return result;
}
