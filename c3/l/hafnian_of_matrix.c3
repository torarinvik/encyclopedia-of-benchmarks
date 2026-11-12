module hafnian_of_matrix;

const usz MAX_N = 16;
const usz MAX_INPUT_VALUES = 1 + MAX_N * MAX_N;
const usz STATES = 1 << MAX_N;
const long MOD = 998244353;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long hafnian_of_matrix(long* input, usz length, char* output, usz capacity)
    @export("hafnian_of_matrix") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    if (n_value < 2 || n_value > (long)MAX_N || n_value % 2 != 0) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n * n) return -1;

    long[MAX_N * MAX_N] matrix;
    for (usz row = 0; row < n; row += 1) {
        for (usz column = 0; column < n; column += 1) {
            long value = input[1 + row * n + column];
            if (value < 0 || value >= MOD || (row == column && value != 0)) return -1;
            matrix[row * MAX_N + column] = value;
        }
    }
    for (usz row = 0; row < n; row += 1)
        for (usz column = 0; column < row; column += 1)
            if (matrix[row * MAX_N + column] != matrix[column * MAX_N + row]) return -1;

    long[STATES] dp;
    for (usz mask = 0; mask < STATES; mask += 1) dp[mask] = 0;
    dp[0] = 1;
    usz full = (1 << n) - 1;
    for (usz mask = 1; mask <= full; mask += 1) {
        usz bits = mask;
        bool odd = false;
        while (bits > 0) {
            odd = !odd;
            bits &= bits - 1;
        }
        if (odd) continue;
        usz first = 0;
        while ((mask & (1 << first)) == 0) first += 1;
        usz without_first = mask ^ (1 << first);
        for (usz second = first + 1; second < n; second += 1) {
            usz bit = 1 << second;
            if ((without_first & bit) == 0) continue;
            usz rest = without_first ^ bit;
            dp[mask] = (dp[mask] + matrix[first * MAX_N + second] * dp[rest]) % MOD;
        }
    }
    if (output == null || capacity < 8) return -2;
    store_i64_le(output, dp[full]);
    return 8;
}
