const MAX_PRODUCT: i64 = 16_777_216;

fn modularInverse(value: i64, modulus: i64) i64 {
    var old_remainder = @mod(value, modulus);
    var remainder = modulus;
    var old_coefficient: i64 = 1;
    var coefficient: i64 = 0;
    while (remainder != 0) {
        const quotient = @divTrunc(old_remainder, remainder);
        const next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        const next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    old_coefficient = @mod(old_coefficient, modulus);
    return old_coefficient;
}

export fn generalized_chinese_remainder_theorem(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 10) return -1;
    const values = input.?[0..length];
    const count = values[0];
    if (count < 1 or count > 4 or length != @as(usize, @intCast(1 + 2 * count))) return -1;
    var product: i64 = 1;
    for (0..@as(usize, @intCast(count))) |index| {
        const residue = values[1 + 2 * index];
        const modulus = values[2 + 2 * index];
        if (modulus < 2 or modulus > 64 or residue < 0 or residue >= modulus) return -1;
        if (product > @divTrunc(MAX_PRODUCT, modulus)) return -1;
        product *= modulus;
    }

    var powers = [_]i64{0} ** 65;
    var residues = [_]i64{0} ** 65;
    for (0..@as(usize, @intCast(count))) |index| {
        const residue = values[1 + 2 * index];
        var remaining = values[2 + 2 * index];
        var prime: i64 = 2;
        while (prime <= remaining) : (prime += 1) {
            if (@mod(remaining, prime) == 0) {
                var prime_power: i64 = 1;
                while (@mod(remaining, prime) == 0) {
                    remaining = @divTrunc(remaining, prime);
                    prime_power *= prime;
                }
                const slot: usize = @intCast(prime);
                if (prime_power > powers[slot]) {
                    powers[slot] = prime_power;
                    residues[slot] = @mod(residue, prime_power);
                }
            }
        }
    }
    for (0..@as(usize, @intCast(count))) |index| {
        const residue = values[1 + 2 * index];
        var remaining = values[2 + 2 * index];
        var prime: i64 = 2;
        while (prime <= remaining) : (prime += 1) {
            if (@mod(remaining, prime) == 0) {
                var prime_power: i64 = 1;
                while (@mod(remaining, prime) == 0) {
                    remaining = @divTrunc(remaining, prime);
                    prime_power *= prime;
                }
                const slot: usize = @intCast(prime);
                if (@mod(residues[slot], prime_power) != @mod(residue, prime_power)) return -2;
            }
        }
    }

    var solution: i64 = 0;
    var combined_modulus: i64 = 1;
    for (2..65) |prime| {
        const modulus = powers[prime];
        if (modulus == 0) continue;
        const inverse = modularInverse(@mod(combined_modulus, modulus), modulus);
        var difference = @mod(residues[prime] - @mod(solution, modulus), modulus);
        if (difference < 0) difference += modulus;
        const multiplier = @mod(difference * inverse, modulus);
        solution += combined_modulus * multiplier;
        combined_modulus *= modulus;
        solution = @mod(solution, combined_modulus);
    }
    return solution;
}
