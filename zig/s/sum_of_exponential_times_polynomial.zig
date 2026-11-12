/// Finite geometric power sum by binary composition of moment blocks.
const MODULUS: i64 = 998244353;
const MAX_DEGREE: usize = 32;
const Moments = [MAX_DEGREE + 1]i64;
const Binomials = [MAX_DEGREE + 1][MAX_DEGREE + 1]i64;

fn sepmShift(source: *const Moments, shift: u64, degree: usize, choose: *const Binomials) Moments {
    var powers: Moments = @splat(0);
    var destination: Moments = @splat(0);
    powers[0] = 1;
    const reduced_shift: i64 = @intCast(shift % @as(u64, @intCast(MODULUS)));
    for (1..degree + 1) |i| powers[i] = @mod(powers[i - 1] * reduced_shift, MODULUS);
    for (0..degree + 1) |d| {
        var total: i64 = 0;
        for (0..d + 1) |k| {
            const term = @mod(choose.*[d][k] * powers[d - k], MODULUS);
            total = @mod(total + term * source.*[k], MODULUS);
        }
        destination[d] = total;
    }
    return destination;
}

export fn sum_of_exponential_times_polynomial(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const r = input[0];
    const degree_value = input[1];
    const n_value = input[2];
    if (r < 0 or r >= MODULUS or degree_value < 0 or degree_value > 32 or
        n_value < 0 or n_value > 1_000_000_000_000_000_000) return -1;
    const degree: usize = @intCast(degree_value);
    var choose: Binomials = @splat(@splat(0));
    choose[0][0] = 1;
    for (1..degree + 1) |d| {
        choose[d][0] = 1;
        choose[d][d] = 1;
        for (1..d) |k| choose[d][k] = @mod(choose[d - 1][k - 1] + choose[d - 1][k], MODULUS);
    }

    var accumulated: Moments = @splat(0);
    var block: Moments = @splat(0);
    block[0] = 1;
    var accumulated_power: i64 = 1;
    var block_power = r;
    var accumulated_length: u64 = 0;
    var block_length: u64 = 1;
    var remaining: u64 = @intCast(n_value);
    while (remaining > 0) {
        if ((remaining & 1) != 0) {
            const shifted = sepmShift(&block, accumulated_length, degree, &choose);
            for (0..degree + 1) |d| accumulated[d] = @mod(accumulated[d] + accumulated_power * shifted[d], MODULUS);
            accumulated_power = @mod(accumulated_power * block_power, MODULUS);
            accumulated_length += block_length;
        }
        const shifted = sepmShift(&block, block_length, degree, &choose);
        for (0..degree + 1) |d| block[d] = @mod(block[d] + block_power * shifted[d], MODULUS);
        block_power = @mod(block_power * block_power, MODULUS);
        block_length <<= 1;
        remaining >>= 1;
    }
    return accumulated[degree];
}
