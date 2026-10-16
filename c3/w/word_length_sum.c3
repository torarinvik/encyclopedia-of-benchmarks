module word_length_sum;

fn long word_length_sum(long* values, usz length) @export("word_length_sum") {
    if (length > 4096 || (length != 0 && values == null)) return -1;
    long total = 0;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 255) return -1;
        if (values[index] != 32) total++;
    }
    return total;
}
