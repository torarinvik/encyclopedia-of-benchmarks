module largest_smallest_words;

fn bool stripped_punctuation(long value) {
    return value == '.' || value == ',' || value == '!' || value == '?' || value == '(' ||
        value == ')' || value == '[' || value == ']' || value == '{' || value == '}';
}

fn void put_u32(char* output, usz offset, uint value) {
    output[offset] = (char)value;
    output[offset + 1] = (char)(value >> 8);
    output[offset + 2] = (char)(value >> 16);
    output[offset + 3] = (char)(value >> 24);
}

fn long largest_smallest_words(long* values, usz length, char* output, usz output_capacity)
    @export("largest_smallest_words") {
    if (values == null || length < 1 || length > 515 || values[0] < 1 || values[0] > 512 ||
        length != 1 + (usz)values[0]) return -1;
    usz text_length = (usz)values[0];
    char text[512];
    for (usz i = 0; i < text_length; i++) {
        long value = values[i + 1];
        if (value < 32 || value > 126) return -1;
        text[i] = (char)value;
    }
    usz small_start = 0, large_start = 0;
    usz small_length = 513, large_length = 0, word_count = 0;
    usz pos = 0;
    while (pos < text_length) {
        while (pos < text_length && text[pos] == ' ') pos++;
        if (pos == text_length) break;
        usz start = pos;
        while (pos < text_length && text[pos] != ' ') pos++;
        usz first = start, last = pos;
        while (first < last && stripped_punctuation(text[first])) first++;
        while (last > first && stripped_punctuation(text[last - 1])) last--;
        usz word_length = last - first;
        if (word_length < small_length) { small_start = first; small_length = word_length; }
        if (word_length > large_length) { large_start = first; large_length = word_length; }
        word_count++;
    }
    if (word_count == 0) return -1;
    usz output_length = 8 + small_length + large_length;
    if (output == null || output_capacity < output_length) return -2;
    put_u32(output, 0, (uint)small_length);
    for (usz i = 0; i < small_length; i++) output[4 + i] = text[small_start + i];
    usz large_header = 4 + small_length;
    put_u32(output, large_header, (uint)large_length);
    for (usz i = 0; i < large_length; i++) output[large_header + 4 + i] = text[large_start + i];
    return (long)output_length;
}
