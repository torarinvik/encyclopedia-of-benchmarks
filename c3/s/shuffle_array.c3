module shuffle_array;

const usz MAX_N = 32;
const usz MAX_PARSEABLE_INPUT_LENGTH = 67;
const usz MAX_OUTPUT_BYTES = 520;
const long I32_MIN = -2147483648;
const long I32_MAX = 2147483647;

fn void store_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long shuffle_array(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("shuffle_array") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    long variant = input[0];
    long n_value = input[1];
    if ((variant != 0 && variant != 1) || n_value < 0 || n_value > (long)MAX_N) return -1L;
    usz n = (usz)n_value;
    usz value_count = variant == 0 ? n : 2 * n;
    usz draw_count = variant == 0 && n > 0 ? n - 1 : 0;
    if (input_length != 2 + value_count + draw_count) return -1L;

    long[2 * MAX_N] result_values = zeroed;
    usz result_count = value_count;
    for (usz index = 0; index < value_count; index++) {
        long value = input[2 + index];
        if (value < I32_MIN || value > I32_MAX) return -1L;
        result_values[index] = value;
    }

    if (variant == 0) {
        for (usz draw_index = 0; draw_index < draw_count; draw_index++) {
            usz current_index = n - 1 - draw_index;
            long chosen_value = input[2 + n + draw_index];
            if (chosen_value < 0 || chosen_value > (long)current_index) return -1L;
            usz chosen_index = (usz)chosen_value;
            long temporary = result_values[current_index];
            result_values[current_index] = result_values[chosen_index];
            result_values[chosen_index] = temporary;
        }
    } else {
        for (usz index = 0; index < n; index++) {
            result_values[2 * index] = input[2 + index];
            result_values[2 * index + 1] = input[2 + n + index];
        }
    }

    usz output_bytes = 8 * (result_count + 1);
    if (output_bytes > MAX_OUTPUT_BYTES || output == null || output_capacity < output_bytes) return -2L;
    store_i64_le(output, 0, (long)result_count);
    for (usz index = 0; index < result_count; index++)
        store_i64_le(output, 8 * (index + 1), result_values[index]);
    return (long)output_bytes;
}
