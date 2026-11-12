const MAX_T: usize = 8;
const MAX_K: i64 = 1_000_000_000;
const MAX_P: i64 = 1_000;

fn modularPower(base_input: i64, exponent_input: i64, modulus: i64) i64 {
    var base = @mod(base_input, modulus);
    var exponent = exponent_input;
    var result = @mod(1, modulus);
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) : (divisor += 1) {
        if (@mod(value, divisor) == 0) return false;
    }
    return true;
}

fn factorDistinct(value_input: i64, factors: *[16]i64) usize {
    var value = value_input;
    var count: usize = 0;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) : (divisor += 1) {
        if (@mod(value, divisor) == 0) {
            factors[count] = divisor;
            count += 1;
            while (@mod(value, divisor) == 0) value = @divTrunc(value, divisor);
        }
    }
    if (value > 1) {
        factors[count] = value;
        count += 1;
    }
    return count;
}

fn primitiveRoot(prime: i64) i64 {
    if (prime == 2) return 1;
    const order = prime - 1;
    var factors: [16]i64 = undefined;
    const count = factorDistinct(order, &factors);
    var candidate: i64 = 2;
    while (candidate < prime) : (candidate += 1) {
        var index: usize = 0;
        while (index < count and modularPower(candidate, @divTrunc(order, factors[index]), prime) != 1) : (index += 1) {}
        if (index == count) return candidate;
    }
    return -1;
}

fn gcdI64(a_input: i64, b_input: i64) i64 {
    var a = a_input;
    var b = b_input;
    while (b != 0) {
        const remainder = @mod(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn modularInverse(value: i64, modulus: i64) i64 {
    var old_t: i64 = 0;
    var new_t: i64 = 1;
    var old_r = modulus;
    var new_r = @mod(value, modulus);
    while (new_r != 0) {
        const quotient = @divTrunc(old_r, new_r);
        const next_t = old_t - quotient * new_t;
        const next_r = old_r - quotient * new_r;
        old_t = new_t;
        new_t = next_t;
        old_r = new_r;
        new_r = next_r;
    }
    if (old_t < 0) old_t += modulus;
    return old_t;
}

fn kthRoot(exponent: i64, residue: i64, prime: i64) i64 {
    if (exponent == 0) return if (residue == 1) 0 else -1;
    if (residue == 0) return 0;
    const order = prime - 1;
    const generator = primitiveRoot(prime);
    var power: i64 = 1;
    var discrete_log: i64 = -1;
    var candidate: i64 = 0;
    while (candidate < order) : (candidate += 1) {
        if (power == residue) {
            discrete_log = candidate;
            break;
        }
        power = @mod(power * generator, prime);
    }
    if (discrete_log < 0) return -1;
    const common = gcdI64(exponent, order);
    if (@mod(discrete_log, common) != 0) return -1;
    const reduced_order = @divTrunc(order, common);
    var root_exponent: i64 = 0;
    if (reduced_order > 1) {
        const inverse = modularInverse(@mod(@divTrunc(exponent, common), reduced_order), reduced_order);
        root_exponent = @mod(@divTrunc(discrete_log, common) * inverse, reduced_order);
    }
    const root = modularPower(generator, root_exponent, prime);
    return if (modularPower(root, exponent, prime) == residue) root else -1;
}

fn writeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn kth_root_mod(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 1 + 3 * MAX_T) return -1;
    const t_value = input[0];
    if (t_value < 1 or t_value > @as(i64, @intCast(MAX_T))) return -1;
    const t: usize = @intCast(t_value);
    if (length != 1 + 3 * t) return -1;
    var triples: [3 * MAX_T]i64 = undefined;
    for (0..t) |test| {
        const offset = 1 + 3 * test;
        const exponent = input[offset];
        const residue = input[offset + 1];
        const prime = input[offset + 2];
        if (exponent < 0 or exponent > MAX_K or prime < 2 or prime > MAX_P or
            residue < 0 or residue >= prime or !isPrime(prime)) return -1;
        triples[3 * test] = exponent;
        triples[3 * test + 1] = residue;
        triples[3 * test + 2] = prime;
    }
    const required = 8 * t;
    if (output == null or capacity < required) return -2;
    for (0..t) |test| {
        writeI64(output, 8 * test, kthRoot(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2]));
    }
    return @intCast(required);
}
