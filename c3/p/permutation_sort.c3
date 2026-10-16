module permutation_sort;

const usz MAX_LENGTH = 8;
const long INVALID_RESULT = -1;

fn bool permutation_sort_is_sorted(long* values, usz length) {
    for (usz index = 1; index < length; index++) {
        if (values[index - 1] > values[index]) return false;
    }
    return true;
}

fn long permutation_sort(long* values, usz length) @export("permutation_sort") {
    if (values == null || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;

    long[MAX_LENGTH] working = zeroed;
    usz[MAX_LENGTH] counters = zeroed;
    for (usz index = 0; index < length; index++) working[index] = values[index];

    long checked = 1;
    if (permutation_sort_is_sorted(&working[0], length)) return checked;

    usz index = 0;
    while (index < length) {
        if (counters[index] < index) {
            usz swap_index = 0;
            if (index % 2 != 0) swap_index = counters[index];
            long temporary = working[swap_index];
            working[swap_index] = working[index];
            working[index] = temporary;
            counters[index]++;
            checked++;
            if (permutation_sort_is_sorted(&working[0], length)) return checked;
            index = 0;
        } else {
            counters[index] = 0;
            index++;
        }
    }
    return INVALID_RESULT;
}
