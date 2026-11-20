const MAX_N: i64 = 22;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn wnGcd(a_value: i64, b_value: i64) i64 {
    var left = a_value;
    var right = b_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn wnNumerator(n: i64) i64 {
    var numerator: i64 = 0;
    var denominator: i64 = 1;
    var k: i64 = 1;
    while (k <= n) : (k += 1) {
        const square = k * k;
        const common = wnGcd(denominator, square);
        const scale = @divTrunc(square, common);
        numerator = numerator * scale + @divTrunc(denominator, common);
        denominator *= scale;
        const factor = wnGcd(numerator, denominator);
        numerator = @divTrunc(numerator, factor);
        denominator = @divTrunc(denominator, factor);
    }
    return numerator;
}

export fn wolstenholme_numbers(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1) return -1;
    const n = values[0];
    if (n < 1 or n > MAX_N) return -1;
    return wnNumerator(n);
}
