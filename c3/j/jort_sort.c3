module jort_sort;

const usz MAX_LENGTH = 64;

fn long jort_sort(long* values, usz length) @export("jort_sort") {
    if (length == 0) return 1;
    if (values == null || length > MAX_LENGTH) return -1;
    long[MAX_LENGTH] copy;
    for (usz i = 0; i < length; i++) copy[i] = values[i];
    for (usz i = 2; i < length; i++) {
        long key = copy[i];
        usz position = i;
        while (position > 1 && copy[position - 1] > key) {
            copy[position] = copy[position - 1];
            position--;
        }
        copy[position] = key;
    }
    for (usz i = 0; i < length; i++) if (copy[i] != values[i]) return 0;
    return 1;
}
