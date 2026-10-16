module columnar_transposition;

const MAX_TEXT = 256;
const MAX_KEY = 32;

fn long columnar_transposition(long* input, usz length, char* output, usz capacity)
    @export("columnar_transposition") {
    if (input == null || length < 3) return -1;
    long operation = input[0];
    long text_value = input[1];
    long raw_key_value = input[2];
    if ((operation != 0 && operation != 1) || text_value < 0 || text_value > MAX_TEXT ||
        raw_key_value < 1 || raw_key_value > MAX_KEY) return -1;
    usz text_length = (usz)text_value;
    usz raw_key_length = (usz)raw_key_value;
    if (length != 3 + text_length + raw_key_length) return -1;
    char[MAX_KEY] key;
    char[MAX_KEY] order;
    usz key_length = 0;
    for (usz i = 0; i < text_length; i++) if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    for (usz i = 0; i < raw_key_length; i++) {
        long value = input[3 + text_length + i];
        if (value < 0 || value > 127) return -1;
        if (value >= 65 && value <= 90) {
            key[key_length++] = (char)value;
        } else if (value >= 97 && value <= 122) {
            key[key_length++] = (char)(value - 32);
        }
    }
    if (key_length == 0) return -1;
    for (usz i = 0; i < key_length; i++) {
        order[i] = (char)i;
        usz position = i;
        while (position > 0 && key[(usz)order[position - 1]] > key[i]) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = (char)i;
    }
    if (text_length == 0) return 0;
    if (output == null || capacity < text_length) return -2;
    usz rows = (text_length + key_length - 1) / key_length;
    if (operation == 0) {
        usz written = 0;
        for (usz rank = 0; rank < key_length; rank++) {
            usz column = (usz)order[rank];
            for (usz row = 0; row < rows; row++) {
                usz index = row * key_length + column;
                if (index < text_length) output[written++] = (char)input[3 + index];
            }
        }
        return (long)written;
    }
    char[MAX_KEY * MAX_TEXT] column_data;
    usz[MAX_KEY] column_lengths;
    usz offset = 0;
    usz short_columns = text_length % key_length;
    for (usz column = 0; column < key_length; column++) {
        column_lengths[column] = short_columns == 0 || column < short_columns ? rows : rows - 1;
    }
    for (usz rank = 0; rank < key_length; rank++) {
        usz column = (usz)order[rank];
        for (usz row = 0; row < column_lengths[column]; row++) {
            column_data[column * MAX_TEXT + row] = (char)input[3 + offset++];
        }
    }
    usz written = 0;
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < key_length; column++) {
            if (row < column_lengths[column]) output[written++] = column_data[column * MAX_TEXT + row];
        }
    }
    return (long)written;
}
