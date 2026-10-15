module longest_palindromic_subsequence;

const usz MAX_VALUES = 128;
fn long longest_palindromic_subsequence(long* values, usz length)
    @export("longest_palindromic_subsequence")
{
    if (length > MAX_VALUES) return -1;
    if (length == 0) return 0;
    long[MAX_VALUES] dp;
    for (usz index = 0; index < MAX_VALUES; index++) dp[index] = 0;
    usz start = length;
    while (start > 0) {
        start--;
        dp[start] = 1;
        long diagonal = 0;
        for (usz end = start + 1; end < length; end++) {
            long previous = dp[end];
            if (values[start] == values[end]) {
                dp[end] = diagonal + 2;
            } else {
                dp[end] = dp[end] > dp[end - 1] ? dp[end] : dp[end - 1];
            }
            diagonal = previous;
        }
    }
    return dp[length - 1];
}
