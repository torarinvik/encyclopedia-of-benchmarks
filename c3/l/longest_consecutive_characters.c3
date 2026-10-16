module longest_consecutive_characters;

fn long longest_consecutive_characters(long *values, usz length, char *output, usz capacity) @export("longest_consecutive_characters") {
    if (values == null || length < 1 || length > 257) return -1;
    long count_value = values[0];
    if (count_value < 1 || count_value > 256 || length != (usz)count_value + 1) return -1;
    usz count = (usz)count_value;
    for (usz i = 0; i < count; i++) if (values[i + 1] < 0 || values[i + 1] > 127) return -1;
    if (output == null || capacity < 3) return -2;

    long best_character = values[1];
    usz best_length = 1, current_length = 1;
    for (usz i = 1; i < count; i++) {
        if (values[i + 1] == values[i]) {
            current_length++;
            if (current_length > best_length) {
                best_length = current_length;
                best_character = values[i + 1];
            }
        } else current_length = 1;
    }
    output[0] = (char)best_character;
    output[1] = (char)(best_length & 255);
    output[2] = (char)(best_length >> 8);
    return 3;
}
