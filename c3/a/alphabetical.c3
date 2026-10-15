module alphabetical;

fn bool is_ascii_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn long lowercase_ascii(long value) {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

fn long alphabetical(long* values, usz length) @export("alphabetical") {
    if (length > 256 || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    if (length == 0) return 0;
    long previous = -1;
    for (usz index = 0; index < length; index++) {
        if (!is_ascii_letter(values[index])) return 0;
        long current = lowercase_ascii(values[index]);
        if (current < previous) return 0;
        previous = current;
    }
    return 1;
}
