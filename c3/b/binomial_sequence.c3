module binomial_sequence;

const long MAX_INDEX = 230L;

fn long binomial_coefficient(long n, long k) {
    if (k == 0 || k == n) return 1;
    if (n < 0) return 0;
    return binomial_coefficient(n - 1, k) + binomial_coefficient(n - 1, k - 1);
}

fn long binomial_sequence(long index) @export("binomial_sequence") {
    if (index < 0 || index > MAX_INDEX) return -1;
    long row = 0;
    long row_start = 0;
    while (index >= row_start + row + 1) {
        row_start += row + 1;
        row += 1;
    }
    return binomial_coefficient(row, index - row_start);
}
