module strassen_matrix_multiplication;

const usz MAX_INPUT_LENGTH = 129;

fn void strassen_multiply(long* a, long* b, long* c, usz n) {
    if (n == 1) { c[0] = a[0] * b[0]; return; }
    usz h = n / 2;
    long[16] x; long[16] y;
    long[16] m1; long[16] m2; long[16] m3; long[16] m4;
    long[16] m5; long[16] m6; long[16] m7;
    for (usz r = 0; r < h; r++) for (usz col = 0; col < h; col++) {
        usz i = r * h + col, q = r * n + col;
        x[i] = a[q] + a[(r + h) * n + col + h];
        y[i] = b[q] + b[(r + h) * n + col + h];
    }
    strassen_multiply(&x[0], &y[0], &m1[0], h);
    for (usz r = 0; r < h; r++) for (usz col = 0; col < h; col++) {
        usz i = r * h + col;
        x[i] = a[(r + h) * n + col] + a[(r + h) * n + col + h]; y[i] = b[r * n + col];
    }
    strassen_multiply(&x[0], &y[0], &m2[0], h);
    for (usz r = 0; r < h; r++) for (usz col = 0; col < h; col++) {
        usz i = r * h + col;
        x[i] = a[r * n + col]; y[i] = b[r * n + col + h] - b[(r + h) * n + col + h];
    }
    strassen_multiply(&x[0], &y[0], &m3[0], h);
    for (usz r = 0; r < h; r++) for (usz col = 0; col < h; col++) {
        usz i = r * h + col;
        x[i] = a[(r + h) * n + col + h]; y[i] = b[(r + h) * n + col] - b[r * n + col];
    }
    strassen_multiply(&x[0], &y[0], &m4[0], h);
    for (usz r = 0; r < h; r++) for (usz col = 0; col < h; col++) {
        usz i = r * h + col;
        x[i] = a[r * n + col] + a[r * n + col + h]; y[i] = b[(r + h) * n + col + h];
    }
    strassen_multiply(&x[0], &y[0], &m5[0], h);
    for (usz r = 0; r < h; r++) for (usz col = 0; col < h; col++) {
        usz i = r * h + col;
        x[i] = a[(r + h) * n + col] - a[r * n + col]; y[i] = b[r * n + col] + b[r * n + col + h];
    }
    strassen_multiply(&x[0], &y[0], &m6[0], h);
    for (usz r = 0; r < h; r++) for (usz col = 0; col < h; col++) {
        usz i = r * h + col;
        x[i] = a[r * n + col + h] - a[(r + h) * n + col + h];
        y[i] = b[(r + h) * n + col] + b[(r + h) * n + col + h];
    }
    strassen_multiply(&x[0], &y[0], &m7[0], h);
    for (usz r = 0; r < h; r++) for (usz col = 0; col < h; col++) {
        usz i = r * h + col;
        c[r * n + col] = m1[i] + m4[i] - m5[i] + m7[i];
        c[r * n + col + h] = m3[i] + m5[i];
        c[(r + h) * n + col] = m2[i] + m4[i];
        c[(r + h) * n + col + h] = m1[i] - m2[i] + m3[i] + m6[i];
    }
}

fn void store_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long strassen_matrix_multiplication(long* input, usz length, char* output, usz capacity) @export("strassen_matrix_multiplication") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value != 1 && n_value != 2 && n_value != 4 && n_value != 8) return -1;
    usz n = (usz)n_value, cells = n * n;
    if (length != 1 + 2 * cells) return -1;
    for (usz i = 0; i < 2 * cells; i++) if (input[1 + i] < -2 || input[1 + i] > 2) return -1;
    usz output_bytes = 8 * cells;
    if (output == null || capacity < output_bytes) return -2;
    long[64] result;
    strassen_multiply(&input[1], &input[1 + cells], &result[0], n);
    for (usz i = 0; i < cells; i++) store_i64_le(result[i], output, i * 8);
    return (long)output_bytes;
}
