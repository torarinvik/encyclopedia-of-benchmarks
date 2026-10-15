module golomb_sequence_validator;

const long MAX_N = 1024;

fn long golomb_sequence_validator(long* input, usz length) @export("golomb_sequence_validator") {
    if (length < 1 || length > 1024) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != n) return -1;
    for (usz index = 1; index < n; index++) {
        if (input[index] < -2147483648 || input[index] > 2147483647) return -1;
    }

    long[1024] dp;
    for (usz index = 0; index < 1024; index++) dp[index] = 0;
    dp[0] = 1;
    for (usz i = 1; i < n; i++) {
        usz previous = (usz)dp[i - 1];
        usz nested = (usz)dp[previous];
        usz source = i - nested;
        dp[i] = 1 + dp[source];
    }
    for (usz index = 1; index < n; index++) {
        if (input[index] != dp[index]) return 0;
    }
    return 1;
}
