module longest_common_subsequence;

// Return the LCS length of two packed ASCII sequences.
fn long longest_common_subsequence(long* packed, usz length) @export("longest_common_subsequence")
{
    if (packed == null || length < 2 || length > 512) return -1;
    long left_length = packed[0];
    long right_length = packed[1];
    if (left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 ||
        length != (usz)(2 + left_length + right_length)) return -1;
    for (usz index = 0; index < (usz)(left_length + right_length); index++) {
        if (packed[2 + index] < 0 || packed[2 + index] > 127) return -1;
    }

    long[256] dp;
    for (usz index = 0; index < 256; index++) dp[index] = 0;
    for (usz left = 0; left < (usz)left_length; left++) {
        long diagonal = 0;
        for (usz right = 1; right <= (usz)right_length; right++) {
            long above = dp[right];
            if (packed[2 + left] == packed[2 + (usz)left_length + right - 1]) {
                dp[right] = diagonal + 1;
            } else if (dp[right - 1] > dp[right]) {
                dp[right] = dp[right - 1];
            }
            diagonal = above;
        }
    }
    return dp[(usz)right_length];
}
