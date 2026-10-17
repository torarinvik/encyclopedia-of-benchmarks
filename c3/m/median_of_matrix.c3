module median_of_matrix;

const usz MAX_ROWS = 16;
const usz MAX_CELLS = 128;
const usz MAX_INPUT_WORDS = 1 + MAX_ROWS + MAX_CELLS;

fn void put_i32_le(char* output, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long median_of_matrix(long* input, usz length, char* output, usz capacity)
        @export("median_of_matrix") {
    if (input == null || length < 1 || length > MAX_INPUT_WORDS) return -1;
    if (input[0] < 0 || input[0] > 16) return -1;

    usz row_count = (usz)input[0];
    usz cursor = 1;
    usz value_count = 0;
    int[128] values;
    for (usz row = 0; row < row_count; row += 1) {
        if (cursor >= length) return -1;
        long row_length = input[cursor];
        cursor += 1;
        if (row_length == -1) continue;
        if (row_length < 0 || row_length > 128) return -1;
        usz cells = (usz)row_length;
        if (cells > MAX_CELLS - value_count || cells > length - cursor) return -1;
        for (usz column = 0; column < cells; column += 1) {
            long value = input[cursor];
            cursor += 1;
            if (value < -2147483648 || value > 2147483647) return -1;
            values[value_count] = (int)value;
            value_count += 1;
        }
    }
    if (cursor != length || value_count == 0) return -1;

    for (usz index = 1; index < value_count; index += 1) {
        int value = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }

    if (output == null || capacity < 4) return -2;
    char[4] buffer;
    put_i32_le(&buffer[0], values[(value_count - 1) / 2]);
    for (usz byte = 0; byte < 4; byte += 1) output[byte] = buffer[byte];
    return 4;
}
