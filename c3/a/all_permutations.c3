module all_permutations;

const usz MAX_LENGTH = 6;
const usz BYTES_PER_VALUE = 4;

fn void store_i32_le(char* output, usz position, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn void generate(int* values, usz n, usz depth, int* current, bool* used,
                 char* output, usz* result_count) {
    if (depth == n) {
        usz row_start = (*result_count) * n * BYTES_PER_VALUE;
        for (usz index = 0; index < n; index++) store_i32_le(output, row_start + index * BYTES_PER_VALUE, current[index]);
        (*result_count)++;
        return;
    }
    for (usz index = 0; index < n; index++) {
        if (used[index]) continue;
        current[depth] = values[index];
        used[index] = true;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[index] = false;
    }
}

// Emit full permutations in the pinned Python traversal order.
fn long all_permutations(long* input, usz length, char* output, usz output_capacity)
    @export("all_permutations") {
    if (input == null || length < 1 || length > MAX_LENGTH + 1) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_LENGTH || length != (usz)n_value + 1) return -1;
    usz n = (usz)n_value;
    int[MAX_LENGTH] values;
    for (usz index = 0; index < n; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) return -1;
        values[index] = (int)value;
    }
    usz permutation_count = 1;
    for (usz factor = 2; factor <= n; factor++) permutation_count *= factor;
    usz required = permutation_count * n * BYTES_PER_VALUE;
    if (output_capacity < required || (required != 0 && output == null)) return -2;
    int[MAX_LENGTH] current;
    bool[MAX_LENGTH] used;
    for (usz index = 0; index < n; index++) used[index] = false;
    usz result_count = 0;
    generate(&values[0], n, 0, &current[0], &used[0], output, &result_count);
    return (long)result_count;
}
