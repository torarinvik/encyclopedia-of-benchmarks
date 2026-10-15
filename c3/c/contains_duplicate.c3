module contains_duplicate;

const usz MAX_VALUES = 1024;

fn void sift_down(long* values, usz root_start, usz length) {
    usz root = root_start;
    while (root < length / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < length && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

// Accepts signed 32-bit values; returns 1 if any repeat, 0 otherwise, -1 if invalid.
fn long contains_duplicate(long* input, usz length) @export("contains_duplicate") {
    if (length > MAX_VALUES || (length != 0 && input == null)) return -1;
    long[MAX_VALUES] values;
    for (usz i = 0; i < length; i++) {
        if (input[i] < -2147483648 || input[i] > 2147483647) return -1;
        values[i] = input[i];
    }
    for (usz start = length / 2; start > 0; start--) sift_down(&values[0], start - 1, length);
    for (usz end = length; end > 1; end--) {
        long temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(&values[0], 0, end - 1);
    }
    for (usz i = 1; i < length; i++) {
        if (values[i - 1] == values[i]) return 1;
    }
    return 0;
}
