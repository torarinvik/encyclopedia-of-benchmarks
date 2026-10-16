module non_empty_subsequences;

const usz MAX_RUNES = 8;
const usz MAX_INPUT_LENGTH = MAX_RUNES + 2;
const usz BYTES_PER_VALUE = 4;

fn bool is_unicode_scalar(long value) {
    return value >= 0 && value <= 0x10ffff && !(value >= 0xd800 && value <= 0xdfff);
}

fn void store_u32_le(char* output, usz position, uint value) {
    for (usz byte = 0; byte < BYTES_PER_VALUE; byte++)
        output[position + byte] = (char)((value >> (byte * 8)) & 255);
}

fn void emit_row(int* current, usz length, char* output, usz* output_cursor, usz* row_count) {
    store_u32_le(output, *output_cursor, (uint)length);
    *output_cursor += BYTES_PER_VALUE;
    for (usz item = 0; item < length; item++) {
        store_u32_le(output, *output_cursor, (uint)current[item]);
        *output_cursor += BYTES_PER_VALUE;
    }
    (*row_count)++;
}

fn void generate(int* values, usz n, usz start, int* current, usz current_length,
                 char* output, usz* output_cursor, usz* row_count) {
    for (usz index = start; index < n; index++) {
        current[current_length] = values[index];
        emit_row(current, current_length + 1, output, output_cursor, row_count);
        generate(values, n, index + 1, current, current_length + 1,
                 output, output_cursor, row_count);
    }
}

fn long non_empty_subsequences(long* input, usz length, char* output, usz output_capacity)
    @export("non_empty_subsequences") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > (long)MAX_RUNES || length != (usz)count_value + 1) return -1;
    usz count = (usz)count_value;
    int[MAX_RUNES] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (!is_unicode_scalar(value)) return -1;
        values[index] = (int)value;
    }

    usz row_count = ((usz)1 << count) - 1;
    usz value_count = count * ((usz)1 << (count - 1));
    usz required = (row_count + value_count) * BYTES_PER_VALUE;
    if (output_capacity < required || output == null) return -2;
    int[MAX_RUNES] current;
    usz output_cursor = 0;
    usz emitted = 0;
    generate(&values[0], count, 0, &current[0], 0, output, &output_cursor, &emitted);
    return (long)emitted;
}
