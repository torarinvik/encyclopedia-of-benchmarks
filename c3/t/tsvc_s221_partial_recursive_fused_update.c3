module tsvc_s221_partial_recursive_fused_update;
extern fn double trunc(double value);
extern fn double fabs(double value);
fn long tsvc_s221_partial_recursive_fused_update(double* input, usz length, double* output, usz capacity)
    @export("tsvc_s221_partial_recursive_fused_update") {
    if (input == null || length < 5 || length > 257) return -1;
    double rn = input[0];
    if (rn != rn || trunc(rn) != rn || rn < 1.0 || rn > 64.0) return -1;
    usz n = (usz)rn;
    if (length != 1 + 4*n) return -1;
    for (usz i = 1; i < length; i++)
        if (input[i] != input[i] || trunc(input[i]) != input[i] || fabs(input[i]) > 2.0) return -1;
    usz required = 2*n;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < n; i++) { output[i] = input[1+i]; output[n+i] = input[1+n+i]; }
    for (usz i = 1; i < n; i++) {
        output[i] = output[i] + input[1+2*n+i] * input[1+3*n+i];
        output[n+i] = (output[n+i-1] + output[i]) + input[1+3*n+i];
    }
    return (long)required;
}
