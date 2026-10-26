module tsvc_s313_dot_product_reduction;
const MAX_N = 64;
extern fn double trunc(double value);
extern fn double fabs(double value);
fn long tsvc_s313_dot_product_reduction(double* input, usz length, double* output, usz capacity)
    @export("tsvc_s313_dot_product_reduction") {
    if (input == null || length < 3 || length > 1 + 2 * MAX_N) return -1;
    double rn = input[0];
    if (rn != rn || trunc(rn) != rn || rn < 1.0 || rn > MAX_N) return -1;
    usz n = (usz)rn;
    if (length != 1 + 2 * n) return -1;
    for (usz i = 1; i < length; i++)
        if (input[i] != input[i] || trunc(input[i]) != input[i] || fabs(input[i]) > 1000.0) return -1;
    if (output == null || capacity < 1) return -2;
    double sum = 0.0;
    for (usz i = 0; i < n; i++) sum += input[1 + i] * input[1 + n + i];
    output[0] = sum;
    return 1;
}
