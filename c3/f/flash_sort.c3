module flash_sort;

const usz MAX_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 65;
const long MAX_VALUE = 1000000;

fn bool valid_length(usz length) { return length <= 1 || (length >= 3 && length <= MAX_LENGTH); }

fn usz class_of(long value, long minimum, long range, usz classes) {
    return (usz)(((long)(classes - 1) * (value - minimum)) / range);
}

fn bool flash_sort_values(long* values, usz length) {
    if (length <= 1) return true;
    long minimum = values[0], maximum = values[0];
    for (usz i = 1; i < length; i++) {
        if (values[i] < minimum) minimum = values[i];
        if (values[i] > maximum) maximum = values[i];
    }
    if (minimum == maximum) return true;
    long range = maximum - minimum;
    usz classes = (9 * length) / 20;
    if (classes < 1) classes = 1;
    usz[MAX_LENGTH] class_ends = zeroed;
    for (usz i = 0; i < length; i++) class_ends[class_of(values[i], minimum, range, classes)]++;
    for (usz i = 1; i < classes; i++) class_ends[i] += class_ends[i - 1];

    usz moves = 0, j = 0, k = classes - 1;
    while (moves < length - 1) {
        while (j > class_ends[k] - 1) {
            j++;
            if (j >= length) return false;
            k = class_of(values[j], minimum, range, classes);
        }
        long flash = values[j];
        while (j != class_ends[k]) {
            k = class_of(flash, minimum, range, classes);
            usz target = --class_ends[k];
            long hold = values[target];
            values[target] = flash;
            flash = hold;
            moves++;
        }
    }
    for (usz i = 1; i < length; i++) {
        long key = values[i], cursor = (long)i;
        while (cursor > 0 && values[(usz)(cursor - 1)] > key) {
            values[(usz)cursor] = values[(usz)(cursor - 1)];
            cursor--;
        }
        values[(usz)cursor] = key;
    }
    return true;
}

fn long flash_sort(long* input, usz length, char* output, usz output_capacity)
    @export("flash_sort") {
    if (length > MAX_INPUT_LENGTH || !valid_length(length) || (length != 0 && input == null)) return -1;
    long[MAX_LENGTH] values = zeroed;
    for (usz i = 0; i < length; i++) {
        if (input[i] < -MAX_VALUE || input[i] > MAX_VALUE) return -1;
        values[i] = input[i];
    }
    usz output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) return -2;
    if (!flash_sort_values(&values[0], length)) return -1;
    for (usz i = 0; i < length; i++) {
        uint bits = (uint)(int)values[i];
        for (usz byte = 0; byte < 4; byte++) output[i * 4 + byte] = (char)(bits >> (8 * byte));
    }
    return (long)output_bytes;
}
