/// Count primes through limit with the Sieve of Atkin.
export fn sieve_of_atkin(limit: i64) i64 {
    if (limit < 0 or limit > 4096) return -1;
    if (limit < 2) return 0;
    const n: usize = @intCast(limit);
    var sieve: [4097]bool = @splat(false);
    var x: usize = 1;
    while (x <= n / x) : (x += 1) {
        const x2 = x * x;
        var y: usize = 1;
        while (y <= n / y) : (y += 1) {
            const y2 = y * y;
            const first = 4 * x2 + y2;
            if (first <= n and (first % 12 == 1 or first % 12 == 5)) sieve[first] = !sieve[first];
            const second = 3 * x2 + y2;
            if (second <= n and second % 12 == 7) sieve[second] = !sieve[second];
            if (x > y) {
                const third = 3 * x2 - y2;
                if (third <= n and third % 12 == 11) sieve[third] = !sieve[third];
            }
        }
    }
    var candidate: usize = 5;
    while (candidate <= n / candidate) : (candidate += 1) {
        if (sieve[candidate]) {
            const square = candidate * candidate;
            var multiple = square;
            while (multiple <= n) : (multiple += square) sieve[multiple] = false;
        }
    }
    var count: i64 = 1;
    if (n >= 3) count += 1;
    var value: usize = 5;
    while (value <= n) : (value += 1) {
        if (sieve[value]) count += 1;
    }
    return count;
}
