export fn problem50(ceiling: i64) i64 {
    if (ceiling < 3 or ceiling > 1_000_000) return -1;
    const limit: usize = @intCast(ceiling);
    var is_prime = [_]bool{false} ** 1_000_000;
    for (0..limit) |index| is_prime[index] = true;
    is_prime[0] = false;
    is_prime[1] = false;
    var value: usize = 2;
    while (value <= (limit - 1) / value) : (value += 1) {
        if (!is_prime[value]) continue;
        var multiple = value * value;
        while (multiple < limit) : (multiple += value) is_prime[multiple] = false;
    }
    var primes = [_]i32{0} ** 100_000;
    var prime_count: usize = 0;
    for (2..limit) |candidate| {
        if (is_prime[candidate]) {
            primes[prime_count] = @intCast(candidate);
            prime_count += 1;
        }
    }
    var longest: usize = 0;
    var largest: i64 = 0;
    for (0..prime_count) |start| {
        const end_start = start + longest;
        var end = start;
        var sum: i64 = 0;
        for (end_start..prime_count) |finish| {
            while (end < finish) : (end += 1) sum += @as(i64, primes[end]);
            if (sum >= ceiling) break;
            if (is_prime[@intCast(sum)]) {
                longest = finish - start;
                largest = sum;
            }
        }
    }
    return largest;
}
