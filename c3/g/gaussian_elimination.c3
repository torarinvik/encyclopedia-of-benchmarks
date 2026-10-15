module gaussian_elimination;

fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz b = 0; b < 8; b++) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}

fn long gaussian_elimination(long* input, usz length, char* output, usz capacity) @export("gaussian_elimination") {
    if (input == null || length < 1) return -1;
    if (input[0] < 2 || input[0] > 8) return -1;
    usz n = input[0].usz();
    if (length != 1 + n*n + n) return -1;
    double matrix[8][9] = {{0.0}};
    for (usz row = 0; row < n; row++) {
        for (usz col = 0; col < n; col++) {
            long value = input[1 + row*n + col];
            if ((row == col && value != 32) || (row != col && value != 0 && value != -1)) return -1;
            if ((row + 1 < col || col + 1 < row) && value != 0) return -1;
            if (row != col && value != input[1 + col*n + row]) return -1;
            matrix[row][col] = value.double();
        }
        long rhs = input[1 + n*n + row];
        if (rhs < -100 || rhs > 100) return -1;
        matrix[row][n] = rhs.double();
    }
    if (output == null || capacity < n*8) return -2;
    for (usz step = 0; step + 1 < n; step++) {
        for (usz row = step + 1; row < n; row++) {
            double factor = matrix[row][step] / matrix[step][step];
            for (usz col = step; col <= n; col++) matrix[row][col] -= factor * matrix[step][col];
        }
    }
    double solution[8] = {0.0};
    usz row = n;
    while (row > 0) {
        row--;
        double sum = 0.0;
        for (usz col = row + 1; col < n; col++) sum += matrix[row][col] * solution[col];
        solution[row] = (matrix[row][n] - sum) / matrix[row][row];
    }
    for (usz i = 0; i < n; i++) put_f64_le(solution[i], output, i*8);
    return (long)(n*8);
}
