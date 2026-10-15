fn sumDivisors(number: u64) i64 {
    var sum: i64 = 0;
    var divisor: u64 = 1;
    while (divisor * divisor <= number) : (divisor += 1) {
        if (number % divisor == 0) {
            sum += @intCast(divisor);
            const other = number / divisor;
            if (other != divisor) sum += @intCast(other);
        }
    }
    return sum;
}

export fn friendly_number(a: u64, b: u64) i64 {
    if (a > 1_000_000 or b > 1_000_000) return -1;
    if (a == 0 or b == 0) return 0;
    const sigma_a = sumDivisors(a);
    const sigma_b = sumDivisors(b);
    return if (sigma_a * @as(i64, @intCast(b)) == sigma_b * @as(i64, @intCast(a))) 1 else 0;
}
