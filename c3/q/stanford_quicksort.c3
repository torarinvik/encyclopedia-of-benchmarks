module stanford_quicksort;

const long SORT_ELEMENTS = 5000;
const long MAX_PREFIX_COUNT = 100;
const usz MAX_OUTPUT_BYTES = 700;

fn void source_quicksort(long* values, long left, long right) {
    long i = left;
    long j = right;
    long pivot = values[(left + right) / 2];
    do {
        while (values[i] < pivot) i++;
        while (pivot < values[j]) j--;
        if (i <= j) {
            long temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
            i++;
            j--;
        }
    } while (i <= j);
    if (left < j) source_quicksort(values, left, j);
    if (i < right) source_quicksort(values, i, right);
}

fn usz append_number(char* buffer, usz used, long value) {
    char[20] reversed;
    usz count = 0;
    if (value < 0) {
        buffer[used++] = '-';
        value = -value;
    }
    do {
        reversed[count++] = (char)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[used++] = reversed[--count];
    buffer[used++] = '\n';
    return used;
}

fn long stanford_quicksort(long prefix_count, char* output, usz output_capacity)
    @export("stanford_quicksort") {
    if (prefix_count < 1 || prefix_count > MAX_PREFIX_COUNT) return -1;
    if (output == null) return -2;

    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    for (long run = 0; run < prefix_count; run++) {
        long[SORT_ELEMENTS + 1] values;
        long state = 74755;
        for (long index = 1; index <= SORT_ELEMENTS; index++) {
            state = (state * 1309 + 13849) & 65535;
            values[index] = state - 50000;
        }
        source_quicksort(&values[0], 1, SORT_ELEMENTS);
        used = append_number(&staged[0], used, values[run + 1]);
    }

    if (output_capacity < used) return -2;
    for (usz index = 0; index < used; index++) output[index] = staged[index];
    return (long)used;
}
