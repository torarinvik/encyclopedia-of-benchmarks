module reservoir_sampling_algorithm_r;

fn long reservoir_sampling_algorithm_r(long* input, usz length, char* output, usz capacity) @export("reservoir_sampling_algorithm_r") {
    if (input == null || length < 2 || length > 130 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > input[0]) return -1;
    usz n = (usz)input[0], k = (usz)input[1];
    if (length != 2+2*n-k) return -1;
    for (usz i = 0; i < n; i++) if (input[2+i] < -1000000 || input[2+i] > 1000000) return -1;
    for (usz i = k; i < n; i++) if (input[2+n+i-k] < 0 || input[2+n+i-k] > (long)i) return -1;
    if (output == null || capacity < 8*k) return -2;
    long[64] reservoir = {};
    for (usz i = 0; i < k; i++) reservoir[i] = input[2+i];
    for (usz i = k; i < n; i++) {
        usz draw = (usz)input[2+n+i-k];
        if (draw < k) reservoir[draw] = input[2+i];
    }
    for (usz i = 0; i < k; i++) {
        ulong bits = (ulong)reservoir[i];
        for (usz j = 0; j < 8; j++) { output[8*i+j] = (char)(bits & 255); bits >>= 8; }
    }
    return (long)(8*k);
}
