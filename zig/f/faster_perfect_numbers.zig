const MAX_INPUT: i64 = 2_305_843_009_213_693_951;

fn getPrimeLimit(value: i64) u64 {
    var scaled: u64 = @as(u64, @intCast(value)) * 8 + 1;
    var limit: u64 = 0;
    while (scaled >= 4) {
        scaled /= 4;
        limit += 1;
    }
    return limit;
}

fn isPrime(value: u64) bool {
    if (value < 2) return false;
    var divisor: u64 = 2;
    while (divisor * divisor <= value) : (divisor += 1) {
        if (@mod(value, divisor) == 0) return false;
    }
    return true;
}

fn isMersennePrime(exponent: u64) bool {
    if (exponent == 2) return true;
    if (exponent < 2) return false;
    const modulus = (@as(u64, 1) << @intCast(exponent)) - 1;
    var residue: u64 = 4;
    var iteration: u64 = 0;
    while (iteration < exponent - 2) : (iteration += 1)
        residue = @mod(residue * residue - 2, modulus);
    return residue == 0;
}

export fn faster_perfect_numbers(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 0 or value > MAX_INPUT) return -1;
    var perfects: [8]i64 = undefined;
    var count: usize = 0;
    const limit = getPrimeLimit(value);
    var exponent: u64 = 2;
    while (exponent <= limit) : (exponent += 1) {
        if (!isPrime(exponent) or !isMersennePrime(exponent)) continue;
        const mersenne = (@as(u64, 1) << @intCast(exponent)) - 1;
        const perfect = mersenne * (@as(u64, 1) << @intCast(exponent - 1));
        if (perfect <= @as(u64, @intCast(value))) {
            perfects[count] = @intCast(perfect);
            count += 1;
        }
    }
    const required = count * 8;
    if (output_capacity < required) return -2;
    for (0..count) |index| {
        const bits: u64 = @intCast(perfects[index]);
        for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(required);
}
