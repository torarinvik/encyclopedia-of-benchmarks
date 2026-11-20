module npb_cg_sparse_outer_product_assembly;

const usz MAX_N = 16;
const usz MAX_NONZER = 4;
const usz MAX_SUPPORT = 5;
const usz MAX_TRIPLETS = 416;
const long MAX_VALUE_MICRO = 1000000;
const long MAX_SHIFT_MICRO = 10000000;
const double SCALE = 1000000.0;
const double RCOND = 0.1;
extern fn double pow(double base, double exponent);

fn void write_u64(char* output, usz* offset, ulong value) {
    for (usz byte = 0; byte < 8; byte++) {
        output[*offset] = (char)(value >> (8 * byte));
        *offset += 1;
    }
}

fn bool valid(long* v, usz length, usz* n_out, usz* nonzer_out) {
    if (v == null || length < 3 || length > 3 + 2 * MAX_N * MAX_NONZER) return false;
    if (v[0] < 2 || v[0] > (long)MAX_N || v[1] < 1 || v[1] > (long)MAX_NONZER ||
        v[2] < 0 || v[2] > MAX_SHIFT_MICRO) return false;
    usz n = (usz)v[0], nonzer = (usz)v[1];
    if (length != 3 + 2 * n * nonzer) return false;
    usz cursor = 3;
    for (usz vector = 0; vector < n; vector++) {
        ulong seen = 0;
        for (usz entry = 0; entry < nonzer; entry++) {
            long coordinate = v[cursor], value = v[cursor + 1];
            cursor += 2;
            if (coordinate < 0 || coordinate >= (long)n || value == 0 ||
                value < -MAX_VALUE_MICRO || value > MAX_VALUE_MICRO) return false;
            ulong bit = 1ul << (usz)coordinate;
            if ((seen & bit) != 0) return false;
            seen |= bit;
        }
    }
    *n_out = n;
    *nonzer_out = nonzer;
    return true;
}

fn long npb_cg_sparse_outer_product_assembly(long* values, usz length,
        char* output, usz capacity) @export("npb_cg_sparse_outer_product_assembly") {
    usz n, nonzer;
    if (!valid(values, length, &n, &nonzer)) return -1;
    char[MAX_TRIPLETS] raw_rows = {0}, raw_columns = {0};
    double[MAX_TRIPLETS] raw_values = {0};
    usz raw_count = 0, cursor = 3;
    for (usz vector = 0; vector < n; vector++) {
        char[MAX_SUPPORT] coordinates = {0};
        double[MAX_SUPPORT] vector_values = {0};
        usz support_count = nonzer;
        bool has_anchor = false;
        for (usz entry = 0; entry < nonzer; entry++) {
            usz coordinate = (usz)values[cursor];
            coordinates[entry] = (char)coordinate;
            vector_values[entry] = (double)values[cursor + 1] / SCALE;
            cursor += 2;
            if (coordinate == vector) { vector_values[entry] = 0.5; has_anchor = true; }
        }
        if (!has_anchor) {
            coordinates[support_count] = (char)vector;
            vector_values[support_count] = 0.5;
            support_count += 1;
        }
        double weight = vector == 0 ? 1.0 :
            (vector + 1 == n ? RCOND : pow(RCOND, (double)vector / (double)(n - 1)));
        for (usz column_slot = 0; column_slot < support_count; column_slot++) {
            double scaled_column = weight * vector_values[column_slot];
            for (usz row_slot = 0; row_slot < support_count; row_slot++) {
                raw_rows[raw_count] = coordinates[row_slot];
                raw_columns[raw_count] = coordinates[column_slot];
                raw_values[raw_count] = vector_values[row_slot] * scaled_column;
                raw_count += 1;
            }
        }
    }
    double diagonal_addend = RCOND - (double)values[2] / SCALE;
    for (usz diagonal = 0; diagonal < n; diagonal++) {
        raw_rows[raw_count] = (char)diagonal;
        raw_columns[raw_count] = (char)diagonal;
        raw_values[raw_count] = diagonal_addend;
        raw_count += 1;
    }

    long[MAX_N + 1] column_pointers = {0};
    char[MAX_N * MAX_N] row_indices = {0};
    double[MAX_N * MAX_N] matrix_values = {0};
    usz nnz = 0;
    for (usz column = 0; column < n; column++) {
        column_pointers[column] = (long)nnz;
        for (usz row = 0; row < n; row++) {
            double sum = 0.0;
            bool touched = false;
            for (usz triple = 0; triple < raw_count; triple++) {
                if ((usz)raw_rows[triple] == row && (usz)raw_columns[triple] == column) {
                    sum += raw_values[triple];
                    touched = true;
                }
            }
            if (touched) {
                row_indices[nnz] = (char)row;
                matrix_values[nnz] = sum;
                nnz += 1;
            }
        }
    }
    column_pointers[n] = (long)nnz;
    usz required = 8 * (2 + (n + 1) + 2 * nnz);
    if (output == null || capacity < required) return -2;
    usz offset = 0;
    write_u64(output, &offset, bitcast((double)n, ulong));
    write_u64(output, &offset, bitcast((double)nnz, ulong));
    for (usz i = 0; i <= n; i++) write_u64(output, &offset, bitcast((double)column_pointers[i], ulong));
    for (usz i = 0; i < nnz; i++) write_u64(output, &offset, bitcast((double)(usz)row_indices[i], ulong));
    for (usz i = 0; i < nnz; i++) write_u64(output, &offset, bitcast(matrix_values[i], ulong));
    return (long)required;
}
