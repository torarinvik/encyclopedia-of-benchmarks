const MAX_N: i64 = 1000;
const ROW_CAPACITY: usize = 1001;

export fn binomial_divisibility_primality_test(
    input_opt: ?[*]const i64,
    length: usize,
) i64 {
    if (input_opt == null or length != 1) return -1;
    const value = input_opt.?[0];
    if (value < 2 or value > MAX_N) return -1;

    const n: usize = @intCast(value);
    var coefficients = [_]i64{0} ** ROW_CAPACITY;
    coefficients[0] = 1;
    var degree: usize = 1;
    while (degree <= n) : (degree += 1) {
        coefficients[degree] = 1;
        var column = degree;
        while (column > 1) {
            column -= 1;
            coefficients[column] = @rem(
                coefficients[column] + coefficients[column - 1],
                value,
            );
        }
    }

    var column: usize = 1;
    while (column < n) : (column += 1) {
        if (coefficients[column] != 0) return 0;
    }
    return 1;
}
