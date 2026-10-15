module word_break;

// Bottom-up word segmentation over packed lowercase ASCII letter codes.
fn long word_break(long* values, usz length) @export("word_break")
{
    if (length < 2 || length > 1122) return -1;
    long text_length_value = values[0];
    long word_count_value = values[1];
    if (text_length_value < 0 || text_length_value > 64 ||
        word_count_value < 0 || word_count_value > 32) return -1;
    usz text_length = (usz)text_length_value;
    usz word_count = (usz)word_count_value;
    usz dictionary_start = 2 + text_length;
    if (length != dictionary_start + word_count * 33) return -1;

    for (usz index = 0; index < text_length; index++) {
        if (values[2 + index] < 1 || values[2 + index] > 26) return -1;
    }
    for (usz word = 0; word < word_count; word++) {
        usz slot = dictionary_start + word * 33;
        long word_length = values[slot];
        if (word_length < 1 || word_length > 32) return -1;
        for (usz index = 0; index < 32; index++) {
            long code = values[slot + 1 + index];
            if (index < (usz)word_length) {
                if (code < 1 || code > 26) return -1;
            } else if (code != 0) {
                return -1;
            }
        }
    }

    bool[65] reachable;
    for (usz index = 0; index < 65; index++) reachable[index] = false;
    reachable[0] = true;
    for (usz start = 0; start < text_length; start++) {
        if (!reachable[start]) continue;
        for (usz word = 0; word < word_count; word++) {
            usz slot = dictionary_start + word * 33;
            usz word_length = (usz)values[slot];
            if (word_length > text_length - start) continue;
            usz index = 0;
            while (index < word_length && values[2 + start + index] == values[slot + 1 + index]) {
                index++;
            }
            if (index == word_length) reachable[start + word_length] = true;
        }
    }
    return reachable[text_length] ? 1 : 0;
}
