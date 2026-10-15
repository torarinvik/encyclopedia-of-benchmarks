module unique_subsequences_count;

fn long unique_subsequences_count(long* input, usz length) @export("unique_subsequences_count") {
    if (input == null || length < 1 || length > 31) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > 30 || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    long[31] dp;
    for (usz i = 0; i < 31; i++) dp[i] = 0;
    for (usz end = n; end > 0; end--) {
        usz i = end - 1;
        bool[128] seen;
        for (usz j = i; j < n; j++) {
            usz ch = (usz)input[j + 1];
            if (seen[ch]) continue;
            seen[ch] = true;
            dp[i] += 1 + dp[j + 1];
        }
    }
    return dp[0];
}
