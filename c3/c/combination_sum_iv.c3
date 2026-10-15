module combination_sum_iv;

const long INVALID_RESULT = (-9223372036854775807 - 1);

// Bottom-up count of ordered denomination sequences.
fn long combination_sum_iv(long* packed, usz length) @export("combination_sum_iv")
{
    if (length < 2 || length > 18) return INVALID_RESULT;
    if (packed[0] < 0 || packed[0] > 16 || packed[1] < 0 || packed[1] > 63) return INVALID_RESULT;
    usz count = (usz)packed[0];
    usz target = (usz)packed[1];
    if (length != count + 2) return INVALID_RESULT;
    for (usz i = 0; i < count; i++) {
        if (packed[i + 2] < 1 || packed[i + 2] > 63) return INVALID_RESULT;
        for (usz j = 0; j < i; j++) {
            if (packed[i + 2] == packed[j + 2]) return INVALID_RESULT;
        }
    }

    long[64] dp;
    for (usz i = 0; i < 64; i++) dp[i] = 0;
    dp[0] = 1;
    for (usz sum = 1; sum <= target; sum++) {
        for (usz i = 0; i < count; i++) {
            usz denomination = (usz)packed[i + 2];
            if (denomination <= sum) dp[sum] += dp[sum - denomination];
        }
    }
    return dp[target];
}
