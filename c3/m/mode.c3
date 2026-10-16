module mode;

// Find the unique mode of a bounded array of small nonnegative integers.
fn long mode(long* values, usz length) @export("mode") {
    if (values == null || length == 0 || length > 4096) return -1;
    usz[256] counts;
    for (usz i = 0; i < 256; i++) counts[i] = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 0 || value > 255) return -1;
        counts[(usz)value]++;
    }
    usz maximum = 0;
    long result = -1;
    bool unique = true;
    for (usz i = 0; i < 256; i++) {
        if (counts[i] > maximum) {
            maximum = counts[i];
            result = (long)i;
            unique = true;
        } else if (counts[i] != 0 && counts[i] == maximum) {
            unique = false;
        }
    }
    return unique ? result : -1;
}
