module strange_printer;

const usz MAX_LENGTH = 8;
const usz TABLE_SIDE = 9;

fn long strange_printer(long* input, usz length) @export("strange_printer") {
    if (input == null || length < 1 || length > 10) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_LENGTH || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    for (usz position = 0; position < n; position++) {
        if (input[position + 1] < 0 || input[position + 1] > 2) return -1;
    }
    if (n == 0) return 0;

    long[TABLE_SIDE * TABLE_SIDE] dp = zeroed;
    for (usz left = n; left > 0;) {
        left--;
        dp[left * TABLE_SIDE + left] = 1;
        for (usz right = left + 1; right < n; right++) {
            long best = dp[(left + 1) * TABLE_SIDE + right] + 1;
            for (usz merge = left + 1; merge <= right; merge++) {
                if (input[left + 1] != input[merge + 1]) continue;
                long middle = merge == left + 1 ? 0 : dp[(left + 1) * TABLE_SIDE + merge - 1];
                long candidate = middle + dp[merge * TABLE_SIDE + right];
                if (candidate < best) best = candidate;
            }
            dp[left * TABLE_SIDE + right] = best;
        }
    }
    return dp[n - 1];
}
