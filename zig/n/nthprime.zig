/// Expanding sieve strategy from the pinned Rust nth-prime routine.
export fn nthprime(nth: i64) i64 {
    if (nth < 1 or nth > 100) return -1;
    var primes: [1600]u64 = [_]u64{0} ** 1600;
    var total_prime: u64 = 0;
    var size_factor: u64 = 2;
    var size: usize = @intCast(nth * 2);

    while (total_prime < @as(u64, @intCast(nth))) {
        if (size > primes.len) return -1;
        for (0..size) |index| primes[index] = 1;
        for (2..size) |index| {
            if (primes[index] == 1) {
                var multiple = index;
                while (multiple < size) : (multiple += 1) {
                    const product = index * multiple;
                    if (product < size) {
                        primes[product] = 0;
                    } else {
                        break;
                    }
                }
            }
        }
        total_prime = 0;
        for (2..size) |index| total_prime += primes[index];
        size_factor += 1;
        size = @intCast(nth * @as(i64, @intCast(size_factor)));
    }

    const used_size = size - @as(usize, @intCast(nth));
    var count: u64 = 0;
    for (2..used_size) |index| {
        count += primes[index];
        if (count == @as(u64, @intCast(nth))) return @intCast(index);
    }
    return -1;
}
