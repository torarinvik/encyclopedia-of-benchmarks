const max_uint53: i64 = 9_007_199_254_740_991;

/// Iterative bitwise XOR for two nonnegative uint53 operands.
export fn uint53_xor(left_input: i64, right_input: i64) i64 {
    if (left_input < 0 or left_input > max_uint53 or right_input < 0 or right_input > max_uint53) return -1;
    var left = left_input;
    var right = right_input;
    var result: i64 = 0;
    var bit: i64 = 1;
    while (left != 0 and right != 0) {
        const left_bit = @mod(left, 2);
        const right_bit = @mod(right, 2);
        result += @mod(left_bit + right_bit, 2) * bit;
        left = @divTrunc(left - left_bit, 2);
        right = @divTrunc(right - right_bit, 2);
        bit *= 2;
    }
    return result + (left + right) * bit;
}
