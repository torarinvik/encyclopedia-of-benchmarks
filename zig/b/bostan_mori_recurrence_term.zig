const MAX_ORDER: usize = 8;
const MODULUS: i64 = 998244353;

fn convolve(left: []const i64, right: []const i64, product: []i64) void {
    @memset(product, 0);
    for (left, 0..) |first, i| {
        for (right, 0..) |second, j| {
            product[i + j] = @mod(product[i + j] + first * second, MODULUS);
        }
    }
}

export fn bostan_mori_recurrence_term(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2) return -1;
    const input = input_opt.?;
    const order_word = input[0];
    const index_word = input[1];
    if (order_word < 1 or order_word > MAX_ORDER or index_word < 0
            or index_word > 1000000000000000000) return -1;
    const order: usize = @intCast(order_word);
    if (length != 2 + 2 * order) return -1;

    var numerator = [_]i64{0} ** MAX_ORDER;
    var denominator = [_]i64{0} ** (MAX_ORDER + 1);
    var initial = [_]i64{0} ** MAX_ORDER;
    denominator[0] = 1;
    for (0..order) |i| {
        const coefficient = input[2 + i];
        initial[i] = input[2 + order + i];
        if (coefficient < 0 or coefficient >= MODULUS
                or initial[i] < 0 or initial[i] >= MODULUS) return -1;
        denominator[i + 1] = @mod(-coefficient, MODULUS);
    }

    var product = [_]i64{0} ** (2 * MAX_ORDER + 1);
    convolve(initial[0..order], denominator[0 .. order + 1], product[0 .. 2 * order]);
    @memcpy(numerator[0..order], product[0..order]);
    var index: u64 = @intCast(index_word);
    while (index > 0) {
        var denominator_negative = [_]i64{0} ** (MAX_ORDER + 1);
        var numerator_product = [_]i64{0} ** (2 * MAX_ORDER + 1);
        var denominator_product = [_]i64{0} ** (2 * MAX_ORDER + 1);
        for (0..order + 1) |i| {
            denominator_negative[i] = if (i % 2 == 0 or denominator[i] == 0)
                denominator[i]
            else
                MODULUS - denominator[i];
        }
        convolve(numerator[0..order], denominator_negative[0 .. order + 1], numerator_product[0 .. 2 * order]);
        convolve(denominator[0 .. order + 1], denominator_negative[0 .. order + 1], denominator_product[0 .. 2 * order + 1]);
        const parity: usize = @intCast(index & 1);
        for (0..order) |i| numerator[i] = numerator_product[2 * i + parity];
        for (0..order + 1) |i| denominator[i] = denominator_product[2 * i];
        index >>= 1;
    }
    return numerator[0];
}
