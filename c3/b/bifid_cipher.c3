module bifid_cipher;

fn long letter_index(long value, bool merge_j) {
    if (value >= 97 && value <= 122) value -= 32;
    if (value < 65 || value > 90) return -1;
    long index = value - 65;
    if (index == 9) {
        if (!merge_j) return -1;
        index = 8;
    } else if (index > 9) {
        index--;
    }
    return index;
}

fn char letter_for_index(usz index) {
    long value = 97 + (long)index;
    if (index >= 9) value++;
    return (char)value;
}

// Fractionate a fixed-square Bifid cipher over one complete message block.
fn long bifid_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("bifid_cipher") {
    if (input == null || length < 2 || length > 258) return -1;
    long mode = input[0];
    long text_length_value = input[1];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > 256)
        return -1;
    usz text_length = (usz)text_length_value;
    if (length != text_length + 2) return -1;

    u8[256] rows;
    u8[256] columns;
    u8[512] coordinates;
    u8[256] result;
    usz result_length = 0;

    if (mode == 0) {
        for (usz i = 0; i < text_length; i++) {
            long value = input[i + 2];
            if (value == 32) continue;
            long index = letter_index(value, true);
            if (index < 0) return -1;
            rows[result_length] = (u8)(index / 5 + 1);
            columns[result_length] = (u8)(index % 5 + 1);
            result_length++;
        }
        for (usz i = 0; i < result_length; i++) {
            coordinates[i] = rows[i];
            coordinates[result_length + i] = columns[i];
        }
        for (usz i = 0; i < result_length; i++) {
            usz position = (usz)(coordinates[2 * i] - 1) * 5
                + (coordinates[2 * i + 1] - 1);
            result[i] = (u8)letter_for_index(position);
        }
    } else {
        result_length = text_length;
        for (usz i = 0; i < text_length; i++) {
            long index = letter_index(input[i + 2], false);
            if (index < 0) return -1;
            coordinates[2 * i] = (u8)(index / 5 + 1);
            coordinates[2 * i + 1] = (u8)(index % 5 + 1);
        }
        for (usz i = 0; i < result_length; i++) {
            usz position = (usz)(coordinates[i] - 1) * 5
                + (coordinates[result_length + i] - 1);
            result[i] = (u8)letter_for_index(position);
        }
    }

    if (output_capacity < result_length || (result_length != 0 && output == null)) return -2;
    for (usz i = 0; i < result_length; i++) output[i] = (char)result[i];
    return (long)result_length;
}
