module binomial_calculate;

fn long binomial_calculate(long* input, usz length) @export("binomial_calculate") {
    if (input == null || length != 2) return -1;
    long n = input[0], k = input[1];
    if (n < 0 || n > 62 || k < 0 || k > n) return -1;
    if (k > n / 2) k = n - k;
    ulong result = 1;
    for (long i = 1; i <= k; ++i) {
        result *= (ulong)(n - k + i);
        result /= (ulong)i;
    }
    return (long)result;
}
