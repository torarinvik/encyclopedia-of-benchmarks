/// Lucas digit product for a binomial coefficient modulo three.
fn triangleBinomialModThree(n_value: i64, k_value: i64) i64 {
    var n = n_value;
    var k = k_value;
    var coefficient: i64 = 1;
    while (n > 0 or k > 0) {
        const n_digit = @mod(n, 3);
        const k_digit = @mod(k, 3);
        if (k_digit > n_digit) return 0;
        if (n_digit == 2 and k_digit == 1) coefficient = @mod(2 * coefficient, 3);
        n = @divTrunc(n, 3);
        k = @divTrunc(k, 3);
    }
    return coefficient;
}

export fn coloured_triangle_reduction(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 258) return -1;
    const input = input_opt.?;
    const n = input[0];
    if (n < 1 or n > 256 or length != @as(usize, @intCast(n + 1))) return -1;
    for (0..@intCast(n)) |index| {
        if (input[index + 1] < 0 or input[index + 1] > 2) return -1;
    }

    const rounds = n - 1;
    var total: i64 = 0;
    for (0..@intCast(n)) |index| {
        total = @mod(total + triangleBinomialModThree(rounds, @intCast(index))
                     * input[index + 1], 3);
    }
    return if (@mod(rounds, 2) == 0) total else @mod(3 - total, 3);
}
