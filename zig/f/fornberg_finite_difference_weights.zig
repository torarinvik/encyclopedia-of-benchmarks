const MODULUS: i64 = 998244353;
const MAX_NODES: usize = 8;
const MAX_INPUT_LENGTH: usize = 12;

fn modNorm(value: i64) i64 {
    const reduced = @rem(value, MODULUS);
    return if (reduced < 0) reduced + MODULUS else reduced;
}

fn modPow(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @rem(result * base, MODULUS);
        base = @rem(base * base, MODULUS);
        exponent >>= 1;
    }
    return result;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn fornberg_finite_difference_weights(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const n_value = values[0];
    const order_value = values[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_NODES)) or order_value < 0
        or order_value > 3 or order_value >= n_value or length != @as(usize, @intCast(n_value)) + 3) return -1;
    const n: usize = @intCast(n_value);
    const target = values[2];
    if (target < 0 or target >= MODULUS) return -1;
    for (0..n) |index| {
        const node = values[3 + index];
        if (node < 0 or node >= MODULUS) return -1;
        for (0..index) |previous| if (node == values[3 + previous]) return -1;
    }

    var table: [8][4]i64 = @splat(@splat(0));
    table[0][0] = 1;
    var previous_product: i64 = 1;
    for (1..n) |new_index| {
        var old_last: [4]i64 = @splat(0);
        for (0..4) |derivative| old_last[derivative] = table[new_index - 1][derivative];
        var product: i64 = 1;
        const node = values[3 + new_index];
        const factor = modNorm(node - target);
        const order: usize = @intCast(order_value);
        const max_derivative = @min(new_index, order);
        for (0..new_index) |old_index| {
            const difference = modNorm(node - values[3 + old_index]);
            product = @rem(product * difference, MODULUS);
            const inverse_difference = modPow(difference, MODULUS - 2);
            var derivative: isize = @intCast(max_derivative);
            while (derivative >= 0) : (derivative -= 1) {
                const d: usize = @intCast(derivative);
                const lower: i64 = if (d == 0) 0 else table[old_index][d - 1];
                const numerator = modNorm(factor * table[old_index][d] - @as(i64, @intCast(d)) * lower);
                table[old_index][d] = @rem(numerator * inverse_difference, MODULUS);
            }
        }
        const product_inverse = modPow(product, MODULUS - 2);
        const last_factor = modNorm(values[2 + new_index] - target);
        for (0..max_derivative + 1) |derivative| {
            const lower: i64 = if (derivative == 0) 0 else old_last[derivative - 1];
            const numerator = modNorm(@as(i64, @intCast(derivative)) * lower
                - last_factor * old_last[derivative]);
            table[new_index][derivative] = @rem(previous_product * product_inverse, MODULUS);
            table[new_index][derivative] = @rem(table[new_index][derivative] * numerator, MODULUS);
        }
        previous_product = product;
    }

    const required = 8 * (n + 1);
    if (output == null or capacity < required) return -2;
    const bytes = output.?;
    storeI64Le(bytes, 0, n_value);
    const order: usize = @intCast(order_value);
    for (0..n) |index| storeI64Le(bytes, 8 * (index + 1), table[index][order]);
    return @intCast(required);
}
