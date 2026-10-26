module harmonic_4_bin_packing;

const usz MAX_N = 32;
const usz MAX_INPUT = 33;
const long CAPACITY = 10000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long harmonic_4_bin_packing(long* input, usz length, char* output, usz capacity)
        @export("harmonic_4_bin_packing") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0];
    if (n64 < 1 || n64 > (long)MAX_N || length != 1 + (usz)n64) return -1;
    usz n = (usz)n64;
    for (usz i = 0; i < n; i += 1) if (input[1 + i] < 1 || input[1 + i] > CAPACITY) return -1;
    usz output_bytes = 8 * (n + 1);
    if (output == null || capacity < output_bytes) return -2;
    long[4] current = {-1, -1, -1, -1};
    long[4] remaining = zeroed;
    long[MAX_N] assignment = zeroed;
    long bins = 0;
    for (usz i = 0; i < n; i += 1) {
        long size = input[1 + i];
        usz kind = size * 2 > CAPACITY ? 0 : size * 3 > CAPACITY ? 1 : size * 4 > CAPACITY ? 2 : 3;
        if (current[kind] < 0 || size > remaining[kind]) {
            current[kind] = bins;
            bins += 1;
            remaining[kind] = CAPACITY;
        }
        assignment[i] = current[kind];
        remaining[kind] -= size;
    }
    store_i64_le(output, 0, bins);
    for (usz i = 0; i < n; i += 1) store_i64_le(output, 8 * (i + 1), assignment[i]);
    return (long)output_bytes;
}
