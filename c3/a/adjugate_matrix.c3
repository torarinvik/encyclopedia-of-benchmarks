module adjugate_matrix;

const usz MAX_N = 6;
const long MODULUS = 998244353;

fn long minor_determinant(long* matrix, usz n, usz skip_row, usz skip_column) {
    usz dimension = n - 1;
    if (dimension == 0) return 1;
    long[MAX_N * MAX_N] minor;
    usz target_row = 0;
    for (usz row = 0; row < n; row += 1) {
        if (row == skip_row) continue;
        usz target_column = 0;
        for (usz column = 0; column < n; column += 1) {
            if (column == skip_column) continue;
            minor[target_row * dimension + target_column] = matrix[row * n + column];
            target_column += 1;
        }
        target_row += 1;
    }

    long[1 << (MAX_N - 1)] dp;
    for (usz index = 0; index < (1 << (MAX_N - 1)); index += 1) dp[index] = 0;
    dp[0] = 1;
    usz limit = 1 << dimension;
    for (usz mask = 0; mask < limit; mask += 1) {
        usz row = 0;
        for (usz bits = mask; bits != 0; bits >>= 1) row += bits & 1;
        if (row == dimension) continue;
        for (usz column = 0; column < dimension; column += 1) {
            if ((mask & (1 << column)) != 0) continue;
            usz inversions = 0;
            for (usz prior = column + 1; prior < dimension; prior += 1)
                inversions += (mask >> prior) & 1;
            usz next = mask | (1 << column);
            long term = dp[mask] * minor[row * dimension + column] % MODULUS;
            if ((inversions & 1) == 0) dp[next] = (dp[next] + term) % MODULUS;
            else dp[next] = (dp[next] - term + MODULUS) % MODULUS;
        }
    }
    return dp[limit - 1];
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long adjugate_matrix(long* input, usz length, char* output, usz capacity)
    @export("adjugate_matrix") {
    if (input == null || length < 2 || length > 1 + MAX_N * MAX_N) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n * n) return -1;

    long[MAX_N * MAX_N] matrix;
    for (usz index = 0; index < n * n; index += 1) {
        long value = input[1 + index];
        if (value < 0 || value >= MODULUS) return -1;
        matrix[index] = value;
    }
    usz output_bytes = 8 * n * n;
    if (output == null || capacity < output_bytes) return -2;
    for (usz row = 0; row < n; row += 1) {
        for (usz column = 0; column < n; column += 1) {
            long value = minor_determinant(&matrix[0], n, column, row);
            if (((row + column) & 1) != 0 && value != 0) value = MODULUS - value;
            store_i64_le(output, 8 * (row * n + column), value);
        }
    }
    return (long)output_bytes;
}
