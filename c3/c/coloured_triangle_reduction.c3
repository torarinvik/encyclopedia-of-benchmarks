module coloured_triangle_reduction;

fn long binomial_mod_three(long n, long k) {
    long coefficient = 1;
    while (n > 0 || k > 0) {
        long n_digit = n % 3;
        long k_digit = k % 3;
        if (k_digit > n_digit) return 0;
        if (n_digit == 2 && k_digit == 1) coefficient = (2 * coefficient) % 3;
        n /= 3;
        k /= 3;
    }
    return coefficient;
}

fn long coloured_triangle_reduction(long* input, usz length) @export("coloured_triangle_reduction") {
    if (input == null || length < 2 || length > 258) return -1;
    long n = input[0];
    if (n < 1 || n > 256 || length != (usz)(n + 1)) return -1;
    for (usz index = 0; index < (usz)n; index++)
        if (input[index + 1] < 0 || input[index + 1] > 2) return -1;

    long rounds = n - 1;
    long total = 0;
    for (long index = 0; index < n; index++)
        total = (total + binomial_mod_three(rounds, index) * input[index + 1]) % 3;
    return rounds % 2 == 0 ? total : (3 - total) % 3;
}
