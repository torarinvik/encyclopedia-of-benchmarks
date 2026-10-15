const MAX_INDEX: i64 = 230;

fn binomialCoefficient(n: i64, k: i64) i64 {
    if (k == 0 or k == n) return 1;
    if (n < 0) return 0;
    return binomialCoefficient(n - 1, k) + binomialCoefficient(n - 1, k - 1);
}

export fn binomial_sequence(index: i64) i64 {
    if (index < 0 or index > MAX_INDEX) return -1;
    var row: i64 = 0;
    var row_start: i64 = 0;
    while (index >= row_start + row + 1) {
        row_start += row + 1;
        row += 1;
    }
    return binomialCoefficient(row, index - row_start);
}
