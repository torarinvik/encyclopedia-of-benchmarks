module tsvc_s451_sincos_vector_map;
extern fn double trunc(double value);
extern fn double fabs(double value);
extern fn double sin(double value);
extern fn double cos(double value);
fn long tsvc_s451_sincos_vector_map(double* input, usz length, double* output, usz capacity)
    @export("tsvc_s451_sincos_vector_map") {
    if (input == null || length < 3 || length > 129) return -1;
    double rn = input[0];
    if (rn != rn || trunc(rn) != rn || rn < 1.0 || rn > 64.0) return -1;
    usz n = (usz)rn;
    if (length != 1 + 2*n) return -1;
    for (usz i = 1; i < length; i++)
        if (input[i] != input[i] || fabs(input[i]) > 10.0) return -1;
    if (output == null || capacity < n) return -2;
    for (usz i = 0; i < n; i++) output[i] = sin(input[1+i]) + cos(input[1+n+i]);
    return (long)n;
}
