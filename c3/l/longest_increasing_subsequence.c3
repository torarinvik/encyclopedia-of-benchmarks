module longest_increasing_subsequence;

// Return the length of a strictly increasing subsequence.
fn long longest_increasing_subsequence(long* values, usz length) @export("longest_increasing_subsequence")
{
    if (length > 512) return -1;
    long[512] dp;
    long longest = 0;
    for (usz index = 0; index < length; index++) {
        dp[index] = 1;
        for (usz previous = 0; previous < index; previous++) {
            if (values[index] > values[previous] && dp[index] < dp[previous] + 1) {
                dp[index] = dp[previous] + 1;
            }
        }
        if (dp[index] > longest) longest = dp[index];
    }
    return longest;
}
