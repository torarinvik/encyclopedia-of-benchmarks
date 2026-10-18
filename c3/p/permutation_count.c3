module permutation_count;

fn long permutation_count(long* input, usz length) @export("permutation_count") {
    if (input == null || length != 2) return -1L;
    long n = input[0], r = input[1];
    if (n < 0 || n > 18 || r < 0 || r > 18) return -1L;
    long result = 1L;
    if (r > n) {
        for (long factor = 2; factor <= n; factor++) result *= factor;
    } else {
        for (long i = 0; i < r; i++) result *= n - i;
    }
    return result;
}
