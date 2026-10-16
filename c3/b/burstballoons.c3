module burstballoons;

const usz MAX_BALLOONS = 128;

// MaxCoins by interval dynamic programming, with each balloon chosen last.
fn long burstballoons(long* values, usz length) @export("burstballoons")
{
    if (length > MAX_BALLOONS || (length > 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 1000) return -1;
    }
    if (length == 0) return 0;

    long[MAX_BALLOONS + 2] padded = zeroed;
    long[MAX_BALLOONS + 2][MAX_BALLOONS + 2] dp = zeroed;
    padded[0] = 1;
    padded[length + 1] = 1;
    for (usz index = 0; index < length; index++) padded[index + 1] = values[index];

    for (usz span = 1; span <= length; span++) {
        for (usz left = 1; left + span - 1 <= length; left++) {
            usz right = left + span - 1;
            long best = 0;
            for (usz last = left; last <= right; last++) {
                long coins = dp[left][last - 1] + dp[last + 1][right]
                    + padded[left - 1] * padded[last] * padded[right + 1];
                if (coins > best) best = coins;
            }
            dp[left][right] = best;
        }
    }
    return dp[1][length];
}
