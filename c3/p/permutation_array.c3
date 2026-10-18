module permutation_array;

const usz MAX_LENGTH = 6;
const usz MAX_PARSEABLE_LENGTH = 8;

fn void store_i32_le(char* output, usz position, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn void generate(int* values, usz n, usz index, char* output, usz* result_count) {
    if (index == n) {
        usz row_start = (*result_count) * n * 4;
        for (usz column = 0; column < n; column++) store_i32_le(output, row_start + column * 4, values[column]);
        (*result_count)++;
        return;
    }
    for (usz position = index; position < n; position++) {
        int saved = values[index];
        values[index] = values[position];
        values[position] = saved;
        generate(values, n, index + 1, output, result_count);
        int restore = values[index];
        values[index] = values[position];
        values[position] = restore;
    }
}

// Keep the pinned Java swap-recursion order and duplicate position rows.
fn long permutation_array(long* input, usz length, char* output, usz output_capacity)
    @export("permutation_array") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
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
    usz required = permutation_count * n * 4;
    if (output_capacity < required || (required != 0 && output == null)) return -2;
    usz result_count = 0;
    generate(&values[0], n, 0, output, &result_count);
    return (long)result_count;
}
