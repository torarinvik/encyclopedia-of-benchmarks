export fn uint53_bitwise_and(n: i64, m: i64) i64 {
    if (n < 0 or m < 0 or n > 9_007_199_254_740_991 or m > 9_007_199_254_740_991) return -1;
    var left = n;
    var right = m;
    var result: i64 = 0;
    var bit: i64 = 1;
    while (left != 0 and right != 0) {
        const left_bit = @mod(left, 2);
        const right_bit = @mod(right, 2);
        result += left_bit * right_bit * bit;
        left = @divTrunc(left - left_bit, 2);
        right = @divTrunc(right - right_bit, 2);
        bit *= 2;
    }
    return result;
}
