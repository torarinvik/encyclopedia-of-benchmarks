module move_hash_to_end;

const usz MAX_TEXT_LENGTH = 256;

fn long move_hash_to_end(long* values, usz length, char* output, usz capacity) @export("move_hash_to_end") {
    if (values == null || length < 1 || length > 258) return -1;
    long text_length = values[0];
    if (text_length < 0 || text_length > MAX_TEXT_LENGTH || length != (usz)text_length + 1) return -1;
    for (usz i = 0; i < (usz)text_length; i++) if (values[i + 1] < 0 || values[i + 1] > 127) return -1;
    if (capacity < (usz)text_length || (text_length > 0 && output == null)) return -2;
    usz position = 0;
    for (usz i = 0; i < (usz)text_length; i++) {
        if (values[i + 1] != 35) { output[position] = (char)values[i + 1]; position++; }
    }
    while (position < (usz)text_length) { output[position] = '#'; position++; }
    return text_length;
}
