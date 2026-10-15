module characters_same;

fn long characters_same(long* values, usz length) @export("characters_same") {
    if (length > 256 || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++)
        if (values[index] < 0 || values[index] > 127) return -1;
    if (length == 0) return 1;
    long first = values[0];
    for (usz index = 1; index < length; index++)
        if (values[index] != first) return 0;
    return 1;
}
