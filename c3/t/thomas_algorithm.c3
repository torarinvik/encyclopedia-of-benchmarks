module thomas_algorithm;

const usz MAX_N = 32;

fn void put_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long thomas_algorithm(long* input, usz length, char* output, usz capacity)
    @export("thomas_algorithm") {
    if (input == null || length < 5 || length > 1 + 4 * MAX_N) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 4 * n) return -1;

    long* lower = input + 1;
    long* diagonal = lower + n;
    long* upper = diagonal + n;
    long* rhs = upper + n;
    if (lower[0] != 0 || upper[n - 1] != 0) return -1;
    for (usz row = 0; row < n; row += 1) {
        if (lower[row] < -16 || lower[row] > 16 ||
            upper[row] < -16 || upper[row] > 16 ||
            diagonal[row] < 17 || diagonal[row] > 64 ||
            rhs[row] < -1000 || rhs[row] > 1000) return -1;
        long lower_abs = lower[row] < 0 ? -lower[row] : lower[row];
        long upper_abs = upper[row] < 0 ? -upper[row] : upper[row];
        if (diagonal[row] <= lower_abs + upper_abs) return -1;
    }
    usz output_bytes = n * 8;
    if (output == null || capacity < output_bytes) return -2;

    double[MAX_N] modified_upper;
    double[MAX_N] modified_rhs;
    double[MAX_N] solution;
    for (usz row = 0; row < n; row += 1) {
        modified_upper[row] = 0.0;
        modified_rhs[row] = 0.0;
        solution[row] = 0.0;
    }
    modified_upper[0] = (double)upper[0] / (double)diagonal[0];
    modified_rhs[0] = (double)rhs[0] / (double)diagonal[0];
    for (usz row = 1; row < n; row += 1) {
        double pivot = (double)diagonal[row] - (double)lower[row] * modified_upper[row - 1];
        if (row + 1 < n) modified_upper[row] = (double)upper[row] / pivot;
        modified_rhs[row] = ((double)rhs[row] - (double)lower[row] * modified_rhs[row - 1]) / pivot;
    }
    solution[n - 1] = modified_rhs[n - 1];
    usz row = n - 1;
    while (row > 0) {
        row -= 1;
        solution[row] = modified_rhs[row] - modified_upper[row] * solution[row + 1];
    }
    for (usz index = 0; index < n; index += 1) put_f64_le(output, index * 8, solution[index]);
    return (long)output_bytes;
}
