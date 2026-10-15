module all_subsequences;

const usz MAX_LENGTH = 8;
const usz BYTES_PER_VALUE = 4;

fn void store_u32_le(char* output, usz position, uint value) {
    for (usz byte = 0; byte < 4; byte++) output[position + byte] = (char)((value >> (byte * 8)) & 255);
}

fn void store_i32_le(char* output, usz position, int value) {
    store_u32_le(output, position, (uint)value);
}

fn void generate(int* values, usz n, usz index, int* current, usz current_length,
                 char* output, usz* output_cursor, usz* result_count) {
    if (index == n) {
        store_u32_le(output, *output_cursor, (uint)current_length);
        *output_cursor += BYTES_PER_VALUE;
        for (usz item = 0; item < current_length; item++) {
            store_i32_le(output, *output_cursor, current[item]);
            *output_cursor += BYTES_PER_VALUE;
        }
        (*result_count)++;
        return;
    }
    generate(values, n, index + 1, current, current_length, output, output_cursor, result_count);
    current[current_length] = values[index];
    generate(values, n, index + 1, current, current_length + 1, output, output_cursor, result_count);
}

// Emit all subsequences with the pinned Python skip branch before include branch.
fn long all_subsequences(long* input, usz length, char* output, usz output_capacity)
    @export("all_subsequences") {
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
    usz result_count = 1;
    for (usz index = 0; index < n; index++) result_count *= 2;
    usz value_count = n == 0 ? 0 : n * (result_count / 2);
    usz required = (result_count + value_count) * BYTES_PER_VALUE;
    if (output_capacity < required || output == null) return -2;
    int[MAX_LENGTH] current;
    usz output_cursor = 0;
    usz emitted = 0;
    generate(&values[0], n, 0, &current[0], 0, output, &output_cursor, &emitted);
    return (long)emitted;
}
