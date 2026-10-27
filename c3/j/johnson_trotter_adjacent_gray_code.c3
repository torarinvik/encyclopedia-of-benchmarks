module johnson_trotter_adjacent_gray_code;

const usz MAX_N = 3;
const usz MAX_OUTPUT_BYTES = 144;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long johnson_trotter_adjacent_gray_code(long* input, usz length, char* output,
        usz capacity) @export("johnson_trotter_adjacent_gray_code") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0], permutation_count = 1;
    for (usz value = 2; value <= n; value += 1) permutation_count *= value;
    usz output_bytes = 8 * n * permutation_count;
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_N] permutation = zeroed;
    long[MAX_N + 1] dirs = zeroed;
    for (usz index = 0; index < n; index += 1) { permutation[index] = index.i64() + 1; dirs[index + 1] = -1; }
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    usz rows = 0;
    while true {
        for (usz index = 0; index < n; index += 1) store_i64_le(&staged[0], 8 * (rows * n + index), permutation[index]);
        rows += 1;
        long largest_mobile = 0;
        usz mobile_position = n;
        for (usz position = 0; position < n; position += 1) {
            long value = permutation[position];
            long neighbor = position.i64() + dirs[(usz)value];
            if (neighbor >= 0 && neighbor < n.i64() && value > permutation[(usz)neighbor] && value > largest_mobile) {
                largest_mobile = value; mobile_position = position;
            }
        }
        if (mobile_position == n) break;
        usz neighbor = (mobile_position.i64() + dirs[(usz)largest_mobile]).usz();
        long temporary = permutation[mobile_position]; permutation[mobile_position] = permutation[neighbor]; permutation[neighbor] = temporary;
        usz value = (usz)largest_mobile + 1;
        while (value <= n) { dirs[value] = -dirs[value]; value += 1; }
    }
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.i64();
}
