module sparse_matrix_det;

const long MOD = 998244353;
const int MAX_N = 8;
const int MAX_K = 64;
const usz MAX_PARSEABLE = 195;

fn long add_mod(long a, long b) { a += b; return a >= MOD ? a - MOD : a; }
fn long sub_mod(long a, long b) { a -= b; return a < 0 ? a + MOD : a; }
fn long mul_mod(long a, long b) { return a * b % MOD; }
fn long pow_mod(long value, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = mul_mod(result, value);
        value = mul_mod(value, value);
        exponent >>= 1;
    }
    return result;
}
fn long next_residue(long* state) { *state = (*state * 48271 + 1) % MOD; return *state; }

fn int berlekamp_massey(long* sequence, long* connection, int length) {
    long[MAX_N + 1] previous = zeroed;
    long[MAX_N + 1] temporary = zeroed;
    for (int i = 0; i <= MAX_N; i++) connection[i] = 0;
    connection[0] = 1; previous[0] = 1;
    int degree = 0, shift = 1, previous_degree = 0;
    long last_discrepancy = 1;
    for (int index = 0; index < length; index++) {
        long discrepancy = sequence[index];
        for (int i = 1; i <= degree; i++)
            discrepancy = add_mod(discrepancy, mul_mod(connection[i], sequence[index - i]));
        if (discrepancy == 0) { shift++; continue; }
        for (int i = 0; i <= MAX_N; i++) temporary[i] = connection[i];
        long scale = mul_mod(discrepancy, pow_mod(last_discrepancy, MOD - 2));
        for (int i = 0; i <= previous_degree; i++) {
            int target = i + shift;
            if (target <= MAX_N) connection[target] = sub_mod(connection[target], mul_mod(scale, previous[i]));
        }
        if (2 * degree <= index) {
            int old_degree = degree; degree = index + 1 - degree;
            for (int i = 0; i <= MAX_N; i++) previous[i] = temporary[i];
            previous_degree = old_degree; last_discrepancy = discrepancy; shift = 1;
        } else shift++;
    }
    return degree;
}

fn long dense_determinant(long* row, long* column, long* entry, int n, int k) {
    long[MAX_N * MAX_N] matrix = zeroed;
    for (int e = 0; e < k; e++) matrix[(int)row[e] * MAX_N + (int)column[e]] = entry[e];
    long determinant = 1;
    for (int c = 0; c < n; c++) {
        int pivot = c;
        while (pivot < n && matrix[pivot * MAX_N + c] == 0) pivot++;
        if (pivot == n) return 0;
        if (pivot != c) {
            for (int j = 0; j < n; j++) {
                long temporary = matrix[c * MAX_N + j];
                matrix[c * MAX_N + j] = matrix[pivot * MAX_N + j];
                matrix[pivot * MAX_N + j] = temporary;
            }
            determinant = MOD - determinant;
        }
        long pivot_value = matrix[c * MAX_N + c];
        determinant = mul_mod(determinant, pivot_value);
        long inverse = pow_mod(pivot_value, MOD - 2);
        for (int i = c + 1; i < n; i++) {
            if (matrix[i * MAX_N + c] == 0) continue;
            long factor = mul_mod(matrix[i * MAX_N + c], inverse);
            for (int j = c + 1; j < n; j++)
                matrix[i * MAX_N + j] = sub_mod(matrix[i * MAX_N + j], mul_mod(factor, matrix[c * MAX_N + j]));
            matrix[i * MAX_N + c] = 0;
        }
    }
    return determinant;
}

fn long sparse_wiedemann(long* row, long* column, long* entry, int n, int k, long seed, bool* success) {
    long[MAX_N] diagonal = zeroed, left = zeroed, vector = zeroed, next = zeroed, weighted = zeroed;
    long[2 * MAX_N] sequence = zeroed;
    long diagonal_product = 1;
    for (int i = 0; i < n; i++) {
        diagonal[i] = next_residue(&seed); if (diagonal[i] == 0) diagonal[i] = 1;
        left[i] = next_residue(&seed); vector[i] = next_residue(&seed);
        diagonal_product = mul_mod(diagonal_product, diagonal[i]);
    }
    for (int step = 0; step < 2 * n; step++) {
        long dot = 0;
        for (int i = 0; i < n; i++) dot = add_mod(dot, mul_mod(left[i], vector[i]));
        sequence[step] = dot;
        for (int i = 0; i < n; i++) weighted[i] = mul_mod(diagonal[i], vector[i]);
        for (int i = 0; i < n; i++) next[i] = 0;
        for (int e = 0; e < k; e++) {
            int r = (int)row[e], c = (int)column[e];
            next[r] = add_mod(next[r], mul_mod(entry[e], weighted[c]));
        }
        for (int i = 0; i < n; i++) vector[i] = next[i];
    }
    long[MAX_N + 1] connection = zeroed;
    if (berlekamp_massey(&sequence[0], &connection[0], 2 * n) != n) { *success = false; return 0; }
    long constant = connection[n];
    if ((n & 1) != 0 && constant != 0) constant = MOD - constant;
    *success = true;
    return mul_mod(constant, pow_mod(diagonal_product, MOD - 2));
}

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[byte] = (char)(bits & 255); bits >>= 8; }
}

fn long sparse_matrix_det(long* input, usz length, char* output, usz capacity)
    @export("sparse_matrix_det") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    long n_value = input[0], k_value = input[1];
    if (n_value < 1 || n_value > MAX_N || k_value < 1 || k_value > MAX_K) return -1;
    int n = (int)n_value, k = (int)k_value;
    if (length != (usz)(2 + 3 * k)) return -1;
    bool[MAX_N * MAX_N] seen = zeroed;
    long[MAX_K] row = zeroed, column = zeroed, entry = zeroed;
    for (int e = 0; e < k; e++) {
        long r = input[2 + 3 * e], c = input[3 + 3 * e], value = input[4 + 3 * e];
        if (r < 0 || r >= n || c < 0 || c >= n || value < 1 || value >= MOD) return -1;
        int index = (int)r * MAX_N + (int)c;
        if (seen[index]) return -1;
        seen[index] = true; row[e] = r; column[e] = c; entry[e] = value;
    }
    long determinant = 0; bool found = false;
    for (int attempt = 0; attempt < 4; attempt++) {
        long seed = 104729 + attempt * 1000003;
        if (seed >= MOD) seed %= MOD;
        determinant = sparse_wiedemann(&row[0], &column[0], &entry[0], n, k, seed, &found);
        if (found) break;
    }
    if (!found) determinant = dense_determinant(&row[0], &column[0], &entry[0], n, k);
    if (output == null || capacity < 8) return -2;
    store_i64_le(output, determinant);
    return 8;
}
