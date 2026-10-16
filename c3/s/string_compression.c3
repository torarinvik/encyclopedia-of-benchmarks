module string_compression;

fn long string_compression(long* input, usz length, char* output, usz output_capacity)
        @export("string_compression") {
    if (length > 64 || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 0 || input[index] > 127) return -1;
    }

    usz encoded_length = 0;
    usz index = 0;
    while (index < length) {
        usz end = index + 1;
        while (end < length && input[end] == input[index]) end++;
        usz count = end - index;
        encoded_length += 1;
        if (count > 1) encoded_length += count >= 10 ? 2 : 1;
        index = end;
    }
    if (output_capacity < encoded_length || (encoded_length != 0 && output == null)) return -2;

    usz write_index = 0;
    index = 0;
    while (index < length) {
        usz end = index + 1;
        while (end < length && input[end] == input[index]) end++;
        usz count = end - index;
        output[write_index++] = (char)input[index];
        if (count > 1) {
            if (count >= 10) output[write_index++] = (char)(48 + count / 10);
            output[write_index++] = (char)(48 + count % 10);
        }
        index = end;
    }
    return (long)write_index;
}
