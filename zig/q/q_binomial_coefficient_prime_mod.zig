const max_t: i64 = 16;
const max_n: i64 = 16;
const max_modulus: i64 = 31;
const max_parseable_input_length: usize = 36;

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn modularPower(base_value: i64, exponent_value: usize, modulus: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent >>= 1;
    }
    return result;
}

export fn q_binomial_coefficient_prime_mod(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_parseable_input_length) {
        return -1;
    }
    const input = input_opt.?;
    const count_value = input[0];
    const modulus = input[1];
    const q_value = input[2];
    if (count_value < 1 or count_value > max_t
        or modulus < 2 or modulus > max_modulus or !isPrime(modulus)
        or q_value < 0 or q_value >= modulus) {
        return -1;
    }
    const count: usize = @intCast(count_value);
    if (length != 3 + 2 * count) return -1;

    var max_row: usize = 0;
    for (0..count) |query| {
        const n_value = input[3 + 2 * query];
        const k_value = input[4 + 2 * query];
        if (n_value < 0 or n_value > max_n or k_value < 0 or k_value > max_n
            or n_value >= modulus or k_value >= modulus) {
            return -1;
        }
        max_row = @max(max_row, @as(usize, @intCast(n_value)));
    }
    if (output_opt == null or capacity < count) return -2;

    var table: [17 * 17]i64 = @splat(0);
    table[0] = 1;
    for (1..max_row + 1) |n| {
        table[n * 17] = 1;
        for (1..n + 1) |k| {
            const previous_same = if (k < n) table[(n - 1) * 17 + k] else 0;
            const weight = modularPower(q_value, n - k, modulus);
            table[n * 17 + k] =
                @rem(previous_same + weight * table[(n - 1) * 17 + k - 1], modulus);
        }
    }

    const output = output_opt.?;
    for (0..count) |query| {
        const n: usize = @intCast(input[3 + 2 * query]);
        const k: usize = @intCast(input[4 + 2 * query]);
        output[query] = @intCast(if (k > n) 0 else table[n * 17 + k]);
    }
    return @intCast(count);
}
