module is_sorted;

fn long is_sorted(long* values, usz length) @export("is_sorted") {
    if (length > 4096 || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -1;
    }
    for (usz index = 1; index < length; index++) {
        if (values[index] < values[index - 1]) return 0;
    }
    return 1;
}
