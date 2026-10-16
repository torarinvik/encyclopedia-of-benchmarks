const MAX_LIMIT: i64 = 1000;
const MOD_LIMIT: i64 = 1_000_000_000;

fn contains(value: i64, divisors: []const i64, length: usize) bool {
    for (0..length) |i| if (divisors[i] == value) return true;
    return false;
}
fn getDivisors(number: i64, divisors: []i64) usize {
    if (number == 1) { divisors[0] = 1; return 1; }
    var count: usize = 0;
    var divisor: i64 = 1;
    while (divisor * divisor <= number + 1) : (divisor += 1) {
        if (@rem(number, divisor) != 0) continue;
        const quotient = @divTrunc(number, divisor);
        if (!contains(divisor, divisors, count)) { divisors[count] = divisor; count += 1; }
        if (!contains(quotient, divisors, count)) { divisors[count] = quotient; count += 1; }
    }
    return count;
}
fn sigma2Source(number: i64) i64 {
    var divisors: [128]i64 = @splat(0);
    const count = getDivisors(number, divisors[0..]);
    var sum: i64 = 0;
    for (1..count) |i| sum += @rem(divisors[i] * divisors[i], MOD_LIMIT);
    return @rem(sum, MOD_LIMIT);
}

export fn problem401(limit: i64) i64 {
    if (limit < 0 or limit > MAX_LIMIT) return -1;
    var sum: i64 = 0;
    var number: i64 = 0;
    while (number <= limit) : (number += 1) sum += sigma2Source(number);
    return @rem(sum, MOD_LIMIT);
}
