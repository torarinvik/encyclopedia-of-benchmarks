module harshad_numbers_in_base;

const long MAX_LIMIT = 10000L;

fn long digit_sum(long number, long base) {
    long sum = 0L;
    while (number > 0L) { sum += number % base; number /= base; }
    return sum;
}

fn usz base_length(long number, long base) {
    usz length = 0;
    do { number /= base; length++; } while (number > 0L);
    return length;
}

fn usz required_length(long limit, long base) {
    usz length = 0;
    for (long number = 1L; number < limit; number++) {
        if (number % digit_sum(number, base) != 0L) continue;
        length += base_length(number, base) + 1;
    }
    return length;
}

fn char digit_char(long digit) {
    return (char)(digit < 10L ? '0' + digit : 'A' + digit - 10L);
}

fn usz append_base(long number, long base, char* output, usz position) {
    char[64] digits;
    usz count = 0;
    do { digits[count++] = digit_char(number % base); number /= base; } while (number > 0L);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

fn long harshad_numbers_in_base(long* values, usz length, char* output,
                                usz output_capacity) @export("harshad_numbers_in_base") {
    if (values == null || length != 2) return -1L;
    long limit = values[0], base = values[1];
    if (limit > MAX_LIMIT || base < 2L || base > 36L) return -1L;
    usz required = required_length(limit, base);
    if (output == null || output_capacity < required) return -2L;
    usz position = 0;
    for (long number = 1L; number < limit; number++) {
        if (number % digit_sum(number, base) != 0L) continue;
        position = append_base(number, base, output, position);
        output[position++] = '\0';
    }
    return (long)position;
}
