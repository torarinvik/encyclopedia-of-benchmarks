module bogo_sort;

fn bool bogo_is_sorted(long* values, usz length) {
    for (usz index = 1; index < length; index++) {
        if (values[index - 1] > values[index]) return false;
    }
    return true;
}

fn void bogo_sort(long* values, usz length) @export("bogo_sort") {
    if (length < 2) return;
    ulong state = 2654435769ul;
    while (!bogo_is_sorted(values, length)) {
        usz index = length - 1;
        while (index > 0) {
            state = (state * 1664525ul + 1013904223ul) % 4294967296ul;
            usz other = (usz)((state / 65536ul) % (ulong)(index + 1));
            long temporary = values[index];
            values[index] = values[other];
            values[other] = temporary;
            index--;
        }
    }
}
