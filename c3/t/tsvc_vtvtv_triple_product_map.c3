module tsvc_vtvtv_triple_product_map;
extern fn double trunc(double value);
extern fn double fabs(double value);
fn long tsvc_vtvtv_triple_product_map(double* input, usz length, double* output, usz capacity)
    @export("tsvc_vtvtv_triple_product_map") {
    if (input == null || length < 4 || length > 193) return -1;
    double rn = input[0];
    if (rn != rn || trunc(rn) != rn || rn < 1.0 || rn > 64.0) return -1;
    usz n = (usz)rn;
    if (length != 1 + 3*n) return -1;
    for (usz i = 1; i < length; i++)
        if (input[i] != input[i] || trunc(input[i]) != input[i] || fabs(input[i]) > 2.0) return -1;
    if (output == null || capacity < n) return -2;
    for (usz i = 0; i < n; i++) output[i] = (input[1+i] * input[1+n+i]) * input[1+2*n+i];
    return (long)n;
}
