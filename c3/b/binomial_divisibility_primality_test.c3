module binomial_divisibility_primality_test;

const usz MAX_N = 1000;

fn long binomial_divisibility_primality_test(long* packed, usz length)
    @export("binomial_divisibility_primality_test") {
    if (packed == null || length != 1) return -1;
    long n_value = packed[0];
    if (n_value < 2 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;

    long[MAX_N + 1] row = zeroed;
    row[0] = 1;
    for (usz degree = 1; degree <= n; degree += 1) {
        row[degree] = 1;
        usz index = degree - 1;
        while (index > 0) {
            row[index] = (row[index] + row[index - 1]) % n_value;
            index -= 1;
        }
    }
    for (usz index = 1; index < n; index += 1)
        if (row[index] != 0) return 0;
    return 1;
}
