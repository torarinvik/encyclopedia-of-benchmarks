/// Calculate C(n, k) by updating one row of Pascal's triangle.
export fn binomial_coefficient(n: u64, k: u64) i64 {
    if (n > 66) return -1;
    if (k > n) return 0;
    if (k == 0) return 1;
    var coefficients: [67]i64 = @splat(0);
    coefficients[0] = 1;
    var row: u64 = 1;
    while (row <= n) : (row += 1) {
        var column = @min(row, k);
        while (column > 0) {
            coefficients[@intCast(column)] += coefficients[@intCast(column - 1)];
            column -= 1;
        }
    }
    return coefficients[@intCast(k)];
}
