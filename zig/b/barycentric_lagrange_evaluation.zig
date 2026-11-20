const MODULUS: i64 = 998244353;
const MAX_NODES: usize = 8;
const MAX_INPUT_LENGTH: usize = 19;

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

export fn barycentric_lagrange_evaluation(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 1 or count_value > @as(i64, @intCast(MAX_NODES))) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 * count + 2) return -1;
    for (values[1..]) |coefficient| {
        if (coefficient < 0 or coefficient >= MODULUS) return -1;
    }
    for (0..count) |left| {
        for (0..left) |right| {
            if (values[1 + left] == values[1 + right]) return -1;
        }
    }

    var weights: [MAX_NODES]i64 = @splat(0);
    for (0..count) |index| {
        var product: i64 = 1;
        const node = values[1 + index];
        for (0..count) |other| {
            if (other == index) continue;
            const difference = @rem(node - values[1 + other] + MODULUS, MODULUS);
            product = @rem(product * difference, MODULUS);
        }
        weights[index] = modPow(product, MODULUS - 2);
    }

    const ordinate_start = 1 + count;
    const query = values[2 * count + 1];
    for (0..count) |index| {
        if (query == values[1 + index]) return values[ordinate_start + index];
    }
    var numerator: i64 = 0;
    var denominator: i64 = 0;
    for (0..count) |index| {
        const difference = @rem(query - values[1 + index] + MODULUS, MODULUS);
        const term = @rem(weights[index] * modPow(difference, MODULUS - 2), MODULUS);
        numerator = @rem(numerator + term * values[ordinate_start + index], MODULUS);
        denominator = @rem(denominator + term, MODULUS);
    }
    if (denominator == 0) return -1;
    return @rem(numerator * modPow(denominator, MODULUS - 2), MODULUS);
}
