const MODULUS: i64 = 998_244_353;
const MAX_NODES: usize = 12;
const MAX_LENGTH: usize = 27;

fn modPow(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, MODULUS);
        base = @mod(base * base, MODULUS);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

export fn newton_divided_difference_interpolation(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_LENGTH) return -1;
    const words = input.?;
    if (words[0] < 1 or words[0] > @as(i64, @intCast(MAX_NODES))) return -1;
    const count: usize = @intCast(words[0]);
    if (length != 2 + 2 * count) return -1;
    var nodes: [MAX_NODES]i64 = undefined;
    var differences: [MAX_NODES]i64 = undefined;
    for (0..count) |i| {
        nodes[i] = words[1 + i];
        differences[i] = words[1 + count + i];
        if (nodes[i] < 0 or nodes[i] >= MODULUS or differences[i] < 0 or differences[i] >= MODULUS) return -1;
        for (0..i) |j| {
            if (nodes[i] == nodes[j]) return -1;
        }
    }
    const query = words[length - 1];
    if (query < 0 or query >= MODULUS) return -1;
    for (1..count) |order| {
        for (0..count - order) |offset| {
            const i = count - 1 - offset;
            var numerator = differences[i] - differences[i - 1];
            if (numerator < 0) numerator += MODULUS;
            var denominator = nodes[i] - nodes[i - order];
            if (denominator < 0) denominator += MODULUS;
            differences[i] = @mod(numerator * modPow(denominator, MODULUS - 2), MODULUS);
        }
    }
    var result = differences[count - 1];
    for (0..count - 1) |offset| {
        const i = count - 2 - offset;
        var factor = query - nodes[i];
        if (factor < 0) factor += MODULUS;
        result = @mod(result * factor + differences[i], MODULUS);
    }
    return result;
}
