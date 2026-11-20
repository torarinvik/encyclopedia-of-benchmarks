module tutte_matrix_randomized_perfect_matching;

const usz MAX_N = 8;
const usz MAX_EDGES = 28;
const usz MAX_INPUT = 87;
const usz MAX_OUTPUT = 80;
const long FIELD_P = 65521;

fn long norm(long value) {
    value %= FIELD_P;
    return value < 0 ? value + FIELD_P : value;
}

fn long mod_pow(long value, ulong exponent) {
    long result = 1, factor = norm(value);
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = (result * factor) % FIELD_P;
        factor = (factor * factor) % FIELD_P;
        exponent >>= 1;
    }
    return result;
}

fn void store_word(char* bytes, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        bytes[word * 8 + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn bool eliminate(long* inverse, char* rows, char* columns, usz n,
        usz pivot_row, usz pivot_column) {
    long[MAX_N * MAX_N] old = zeroed;
    for (usz index = 0; index < MAX_N * MAX_N; index += 1) old[index] = inverse[index];
    long pivot = old[pivot_row * MAX_N + pivot_column];
    if (pivot == 0) return false;
    long inverse_pivot = mod_pow(pivot, (ulong)(FIELD_P - 2));
    for (usz row = 0; row < n; row += 1) {
        for (usz column = 0; column < n; column += 1) {
            usz index = row * MAX_N + column;
            if (rows[row] != 0 && row != pivot_row && columns[column] != 0 && column != pivot_column) {
                long correction = (old[row * MAX_N + pivot_column] * old[pivot_row * MAX_N + column]) % FIELD_P;
                inverse[index] = norm(old[index] - correction * inverse_pivot);
            } else inverse[index] = 0;
        }
    }
    rows[pivot_row] = 0;
    columns[pivot_column] = 0;
    return true;
}

fn long tutte_matrix_randomized_perfect_matching(long* input, usz length,
        char* output, usz capacity) @export("tutte_matrix_randomized_perfect_matching") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], edge_count_value = input[1];
    if (n_value < 2 || n_value > (long)MAX_N || (n_value & 1) != 0 ||
        edge_count_value < 0 || edge_count_value > (long)MAX_EDGES) return -1;
    usz n = (usz)n_value, edge_count = (usz)edge_count_value;
    if (edge_count > n * (n - 1) / 2 || length != 2 + 3 * edge_count) return -1;

    long[MAX_N * MAX_N] matrix = zeroed;
    long prior_u = -1, prior_v = -1;
    for (usz edge = 0; edge < edge_count; edge += 1) {
        long u_value = input[2 + 3 * edge], v_value = input[3 + 3 * edge];
        long substitution = input[4 + 3 * edge];
        if (u_value < 0 || v_value <= u_value || v_value >= n_value ||
            u_value < prior_u || (u_value == prior_u && v_value <= prior_v) ||
            substitution < 1 || substitution >= FIELD_P) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        matrix[u * MAX_N + v] = substitution;
        matrix[v * MAX_N + u] = FIELD_P - substitution;
        prior_u = u_value;
        prior_v = v_value;
    }

    long[MAX_N * (2 * MAX_N)] augmented = zeroed;
    for (usz row = 0; row < n; row += 1) {
        for (usz column = 0; column < n; column += 1)
            augmented[row * (2 * MAX_N) + column] = matrix[row * MAX_N + column];
        augmented[row * (2 * MAX_N) + n + row] = 1;
    }
    bool singular = false;
    for (usz column = 0; column < n; column += 1) {
        usz pivot_row = column;
        while (pivot_row < n && augmented[pivot_row * (2 * MAX_N) + column] == 0) pivot_row += 1;
        if (pivot_row == n) { singular = true; break; }
        if (pivot_row != column) {
            for (usz j = 0; j < 2 * n; j += 1) {
                long temp = augmented[column * (2 * MAX_N) + j];
                augmented[column * (2 * MAX_N) + j] = augmented[pivot_row * (2 * MAX_N) + j];
                augmented[pivot_row * (2 * MAX_N) + j] = temp;
            }
        }
        long inverse_pivot = mod_pow(augmented[column * (2 * MAX_N) + column], (ulong)(FIELD_P - 2));
        for (usz j = 0; j < 2 * n; j += 1)
            augmented[column * (2 * MAX_N) + j] = (augmented[column * (2 * MAX_N) + j] * inverse_pivot) % FIELD_P;
        for (usz row = 0; row < n; row += 1) {
            if (row == column) continue;
            long factor = augmented[row * (2 * MAX_N) + column];
            if (factor == 0) continue;
            for (usz j = 0; j < 2 * n; j += 1)
                augmented[row * (2 * MAX_N) + j] = norm(augmented[row * (2 * MAX_N) + j] - factor * augmented[column * (2 * MAX_N) + j]);
        }
    }

    long[MAX_N + 2] result = zeroed;
    usz result_size = 2;
    if (!singular) {
        long[MAX_N * MAX_N] inverse = zeroed;
        for (usz row = 0; row < n; row += 1)
            for (usz column = 0; column < n; column += 1)
                inverse[row * MAX_N + column] = augmented[row * (2 * MAX_N) + n + column];
        char[MAX_N] rows = zeroed, columns = zeroed;
        for (usz i = 0; i < n; i += 1) { rows[i] = 1; columns[i] = 1; }
        bool failed = false;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            if (columns[vertex] == 0) continue;
            usz partner = MAX_N;
            for (usz candidate = 0; candidate < n; candidate += 1) {
                if (rows[candidate] != 0 && candidate != vertex &&
                    matrix[vertex * MAX_N + candidate] != 0 && inverse[candidate * MAX_N + vertex] != 0) {
                    partner = candidate;
                    break;
                }
            }
            if (partner == MAX_N || result_size + 2 > MAX_N + 2) { failed = true; break; }
            result[result_size] = (long)vertex;
            result[result_size + 1] = (long)partner;
            result_size += 2;
            if (!eliminate(&inverse[0], &rows[0], &columns[0], n, partner, vertex) ||
                !eliminate(&inverse[0], &rows[0], &columns[0], n, vertex, partner)) {
                failed = true;
                break;
            }
        }
        if (failed) result_size = 2;
        else { result[0] = 1; result[1] = (long)(n / 2); }
    }
    usz output_bytes = result_size * 8;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    for (usz word = 0; word < result_size; word += 1) store_word(&staged[0], word, result[word]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return (long)output_bytes;
}
