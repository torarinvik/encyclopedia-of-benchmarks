module linear_probing_sort;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

const usz MAX_LENGTH = 1024;

fn void insertion_sort(long* values, usz length) {
    for (usz index = 1; index < length; index++) {
        long key = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            position--;
        }
        values[position] = key;
    }
}

fn void linear_probing_sort(long* values, usz length) @export("linear_probing_sort") {
    if (values == null || length < 2) return;
    if (length > MAX_LENGTH) {
        insertion_sort(values, length);
        return;
    }

    long minimum = values[0];
    long maximum = values[0];
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 255) {
            insertion_sort(values, length);
            return;
        }
        if (values[index] < minimum) minimum = values[index];
        if (values[index] > maximum) maximum = values[index];
    }

    usz main_slots = 256 * (length + 1) + 1;
    usz table_length = main_slots + length;
    long* table = (long*)calloc(table_length, sizeof(long));
    if (table == null) {
        insertion_sort(values, length);
        return;
    }

    long span = maximum - minimum;
    for (usz index = 0; index < length; index++) {
        usz home = span == 0 ? 0 : (usz)((values[index] - minimum) * (long)(main_slots - 1) / span);
        usz slot = home;
        while (table[slot] != 0) slot++;
        table[slot] = values[index] + 1;
    }
    usz output = 0;
    for (usz slot = 0; slot < table_length; slot++) {
        if (table[slot] != 0) values[output++] = table[slot] - 1;
    }
    free(table);
}
