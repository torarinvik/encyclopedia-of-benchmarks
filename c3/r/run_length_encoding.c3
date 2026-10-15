module run_length_encoding;

// Encode runs as an unambiguous decimal count followed by an ASCII byte.
fn long run_length_encoding(long* input, usz length, char* output, usz output_capacity)
        @export("run_length_encoding") {
    if (length > 66) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 1 || input[index] > 127 ||
            (input[index] >= 48 && input[index] <= 57)) return -1;
    }

    usz encoded_length = 0;
    usz index = 0;
    while (index < length) {
        usz end = index + 1;
        while (end < length && input[end] == input[index]) end++;
        usz count = end - index;
        encoded_length += count >= 10 ? 3 : 2;
        index = end;
    }
    if (output_capacity < encoded_length) return -2;

    usz write_index = 0;
    index = 0;
    while (index < length) {
        usz end = index + 1;
        while (end < length && input[end] == input[index]) end++;
        usz count = end - index;
        if (count >= 10) {
            output[write_index++] = (char)(48 + count / 10);
        }
        output[write_index++] = (char)(48 + count % 10);
        output[write_index++] = (char)input[index];
        index = end;
    }
    return (long)write_index;
}
