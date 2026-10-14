/// Scan proper divisors under the shared signed 64-bit contract.
export fn aliquot_sum(n: i64) i64 {
    if (n < 0) return -1;
    var sum: i64 = 0;
    var divisor: i64 = 1;
    while (divisor <= @divTrunc(n, 2)) : (divisor += 1) {
        if (@rem(n, divisor) == 0) {
            if (sum > 9223372036854775807 - divisor) return -1;
            sum += divisor;
        }
    }
    return sum;
}
