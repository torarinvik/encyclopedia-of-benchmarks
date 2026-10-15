module shortest_common_supersequence_length;

// Return shortest common supersequence length for two packed ASCII sequences.
fn long shortest_common_supersequence_length(long* packed, usz length) @export("shortest_common_supersequence_length")
{
    if (packed == null || length < 2 || length > 512) return -1;
    long m = packed[0];
    long n = packed[1];
    if (m < 0 || m > 255 || n < 0 || n > 255 || length != (usz)(2 + m + n)) return -1;
    for (usz k = 0; k < (usz)(m + n); k++) {
        if (packed[2 + k] < 0 || packed[2 + k] > 127) return -1;
    }

    usz columns = (usz)(n + 1);
    long[65536] dp;
    for (usz k = 0; k < 65536; k++) dp[k] = 0;
    for (usz i = 1; i <= (usz)m; i++) {
        for (usz j = 1; j <= (usz)n; j++) {
            usz cell = i * columns + j;
            if (packed[1 + i] == packed[1 + (usz)m + j])
                dp[cell] = dp[(i - 1) * columns + j - 1] + 1;
            else {
                long above = dp[(i - 1) * columns + j];
                long left = dp[i * columns + j - 1];
                dp[cell] = above > left ? above : left;
            }
        }
    }
    return m + n - dp[(usz)m * columns + (usz)n];
}
