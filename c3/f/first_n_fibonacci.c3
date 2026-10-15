module first_n_fibonacci;

const long MIN_COUNT = 3L;
const long MAX_COUNT = 79L;

fn usz decimal_length(long number) {
    usz length = 1;
    while (number >= 10L) { number /= 10L; length++; }
    return length;
}

fn usz required_length(long count) {
    usz bytes = 0;
    long previous = 0L, current = 1L;
    for (long index = 0L; index < count; index++) {
        long value;
        if (index == 0L) value = 0L;
        else if (index == 1L) value = 1L;
        else { value = previous + current; previous = current; current = value; }
        bytes += decimal_length(value) + 1;
    }
    return bytes;
}

fn usz append_decimal(long number, char* output, usz position) {
    char[20] digits;
    usz count = 0;
    do { digits[count++] = (char)('0' + number % 10L); number /= 10L; } while (number > 0L);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

fn long first_n_fibonacci(long* values, usz length, char* output,
                          usz output_capacity) @export("first_n_fibonacci") {
    if (values == null || length != 1) return -1L;
    long count = values[0];
    if (count < MIN_COUNT || count > MAX_COUNT) return -1L;
    usz required = required_length(count);
    if (output == null || output_capacity < required) return -2L;
    usz position = 0;
    long previous = 0L, current = 1L;
    for (long index = 0L; index < count; index++) {
        long value;
        if (index == 0L) value = 0L;
        else if (index == 1L) value = 1L;
        else { value = previous + current; previous = current; current = value; }
        position = append_decimal(value, output, position);
        output[position++] = '\0';
    }
    return (long)position;
}
