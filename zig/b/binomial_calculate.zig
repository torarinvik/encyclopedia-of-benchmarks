const INVALID_RESULT: i64 = -1;

pub export fn binomial_calculate(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return INVALID_RESULT;
    const n = input[0];
    var k = input[1];
    if (n < 0 or n > 62 or k < 0 or k > n) return INVALID_RESULT;
    if (k > @divTrunc(n, 2)) k = n - k;
    var result: u64 = 1;
    var i: i64 = 1;
    while (i <= k) : (i += 1) {
        result *= @intCast(n - k + i);
        result = @divTrunc(result, @as(u64, @intCast(i)));
    }
    return @intCast(result);
}
