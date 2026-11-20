const MAX_COUNT: i64 = 6;

fn smallPrime(value: u64) bool {
    if (value < 2) return false;
    var divisor: u64 = 2;
    while (divisor <= value / divisor) : (divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn multiplyMod(left: u64, right: u64, modulus: u64) u64 {
    return (left * right) % modulus;
}

fn powerMod(initial_base: u64, initial_exponent: u64, modulus: u64) u64 {
    var base = initial_base % modulus;
    var exponent = initial_exponent;
    var result: u64 = 1;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = multiplyMod(result, base, modulus);
        exponent >>= 1;
        if (exponent != 0) base = multiplyMod(base, base, modulus);
    }
    return result;
}

fn primePrefix(value: u64) bool {
    const small_primes = [_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37 };
    const bases = [_]u64{ 2, 7, 61 };
    if (value < 2) return false;
    for (small_primes) |prime| {
        if (value == prime) return true;
        if (value % prime == 0) return false;
    }
    var odd_part = value - 1;
    var twos: u32 = 0;
    while ((odd_part & 1) == 0) {
        odd_part >>= 1;
        twos += 1;
    }
    for (bases) |base| {
        var witness = powerMod(base, odd_part, value);
        if (witness == 1 or witness == value - 1) continue;
        var round: u32 = 1;
        while (round < twos and witness != value - 1) : (round += 1) {
            witness = multiplyMod(witness, witness, value);
        }
        if (witness != value - 1) return false;
    }
    return true;
}

export fn smarandache_wellin_prime_prefix_scan(raw: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const input = raw orelse return -1;
    if (length < 1 or length > 2) return -1;
    if (input[0] < 0 or input[0] > MAX_COUNT or length != 1) return -1;

    var values = [_]u64{0} ** 3;
    var result_count: usize = 0;
    var prefix: u64 = 0;
    var candidate: u64 = 2;
    var step: i64 = 0;
    while (step < input[0]) : (step += 1) {
        while (!smallPrime(candidate)) candidate += if (candidate == 2) 1 else 2;
        var scale: u64 = 10;
        while (scale <= candidate) scale *= 10;
        prefix = prefix * scale + candidate;
        if (primePrefix(prefix)) {
            values[result_count] = prefix;
            result_count += 1;
        }
        candidate += if (candidate == 2) 1 else 2;
    }

    const byte_count = result_count * 8;
    const destination = output orelse return -2;
    if (capacity < byte_count) return -2;
    var staged = [_]u8{0} ** 24;
    for (0..result_count) |item| {
        for (0..8) |byte| staged[item * 8 + byte] = @truncate(values[item] >> @intCast(byte * 8));
    }
    for (0..byte_count) |byte| destination[byte] = staged[byte];
    return @intCast(byte_count);
}
