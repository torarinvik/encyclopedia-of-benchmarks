module integer_partition;

const long MAX_N = 300;
const long STRIDE = 300;

fn long integer_partition(long m) @export("integer_partition")
{
    if (m < 1 || m > MAX_N) return -9223372036854775807 - 1;
    long[(MAX_N + 1) * STRIDE] memo;
    for (long i = 0; i < (MAX_N + 1) * STRIDE; i++) memo[i] = 0;
    for (long i = 0; i <= m; i++) memo[i * STRIDE] = 1;
    for (long n = 0; n <= m; n++) {
        for (long k = 1; k < m; k++) {
            memo[n * STRIDE + k] += memo[n * STRIDE + k - 1];
            if (n - k > 0) memo[n * STRIDE + k] += memo[(n - k - 1) * STRIDE + k];
        }
    }
    return memo[m * STRIDE + m - 1];
}
