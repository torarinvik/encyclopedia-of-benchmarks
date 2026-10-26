module tsvc_s111_odd_index_neighbor_update;
const MAX_N = 64;
extern fn double trunc(double value);
extern fn double fabs(double value);
fn long tsvc_s111_odd_index_neighbor_update(double* input, usz length, double* output, usz capacity)
    @export("tsvc_s111_odd_index_neighbor_update") {
    if (input == null || length < 3 || length > 129) return -1;
    double rn = input[0];
    if (rn != rn || trunc(rn) != rn || rn < 1.0 || rn > MAX_N) return -1;
    usz n = (usz)rn;
    if (length != 1 + 2 * n) return -1;
    for (usz i = 1; i < length; i++)
        if (input[i] != input[i] || trunc(input[i]) != input[i] || fabs(input[i]) > 1000.0) return -1;
    if (output == null || capacity < n) return -2;
    for (usz i = 0; i < n; i++) output[i] = input[1 + i];
    for (usz i = 1; i < n; i += 2) output[i] = input[i] + input[1 + n + i];
    return (long)n;
}
