module tsvc_s275_column_conditional_axpy_recurrence;
const MAX_N = 8;
extern fn double trunc(double value);
extern fn double fabs(double value);
fn long tsvc_s275_column_conditional_axpy_recurrence(double* input, usz length,
    double* output, usz capacity) @export("tsvc_s275_column_conditional_axpy_recurrence") {
    if (input == null || length < 2 || length > 193) return -1;
    double rn = input[0];
    if (rn != rn || trunc(rn) != rn || rn < 1.0 || rn > MAX_N) return -1;
    usz n = (usz)rn, cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    for (usz i = 1; i < length; i++)
        if (input[i] != input[i] || trunc(input[i]) != input[i] || fabs(input[i]) > 16.0) return -1;
    if (output == null || capacity < cells) return -2;
    double[MAX_N * MAX_N] a;
    for (usz i = 0; i < cells; i++) a[i] = input[1 + i];
    usz bs = 1 + cells, cs = 1 + 2 * cells;
    for (usz col = 0; col < n; col++) {
        if (a[col] > 0.0) {
            for (usz row = 1; row < n; row++) {
                usz index = row * n + col;
                a[index] = a[index - n] + input[bs + index] * input[cs + index];
            }
        }
    }
    for (usz i = 0; i < cells; i++) output[i] = a[i];
    return (long)cells;
}
