module remove_duplicate;

fn int compare_words(long* values, usz start_a, usz length_a, usz start_b, usz length_b) {
    usz common = length_a < length_b ? length_a : length_b;
    for (usz index = 0; index < common; index++) {
        long a = values[1 + start_a + index];
        long b = values[1 + start_b + index];
        if (a != b) return a < b ? -1 : 1;
    }
    if (length_a < length_b) return -1;
    if (length_a > length_b) return 1;
    return 0;
}

fn long remove_duplicate(long* values, usz length, char* output, usz output_capacity)
    @export("remove_duplicate") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > 1024 ||
        length != 1 + (usz)values[0]) return -1;
    usz text_length = (usz)values[0];
    for (usz index = 0; index < text_length; index++) {
        long byte = values[index + 1];
        if (byte != 32 && (byte < 'a' || byte > 'z')) return -1;
    }
    usz[512] starts;
    usz[512] lengths;
    usz word_count = 0;
    usz cursor = 0;
    while (cursor < text_length) {
        if (values[cursor + 1] == 32) { cursor++; continue; }
        starts[word_count] = cursor;
        while (cursor < text_length && values[cursor + 1] != 32) cursor++;
        lengths[word_count] = cursor - starts[word_count];
        word_count++;
    }
    for (usz index = 1; index < word_count; index++) {
        usz key_start = starts[index];
        usz key_length = lengths[index];
        usz position = index;
        while (position > 0 && compare_words(values, starts[position - 1], lengths[position - 1],
                                              key_start, key_length) > 0) {
            starts[position] = starts[position - 1];
            lengths[position] = lengths[position - 1];
            position--;
        }
        starts[position] = key_start;
        lengths[position] = key_length;
    }
    usz output_length = 0;
    usz unique_count = 0;
    for (usz index = 0; index < word_count; index++) {
        if (index > 0 && compare_words(values, starts[index - 1], lengths[index - 1],
                                       starts[index], lengths[index]) == 0) continue;
        if (unique_count > 0) output_length++;
        output_length += lengths[index];
        unique_count++;
    }
    if (output_length > output_capacity || (output_length > 0 && output == null)) return -2;
    usz written = 0;
    usz emitted = 0;
    for (usz index = 0; index < word_count; index++) {
        if (index > 0 && compare_words(values, starts[index - 1], lengths[index - 1],
                                       starts[index], lengths[index]) == 0) continue;
        if (emitted > 0) { output[written] = ' '; written++; }
        for (usz byte = 0; byte < lengths[index]; byte++) {
            output[written] = (char)values[1 + starts[index] + byte];
            written++;
        }
        emitted++;
    }
    return (long)output_length;
}
