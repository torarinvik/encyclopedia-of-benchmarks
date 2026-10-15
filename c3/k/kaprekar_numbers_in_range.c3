module kaprekar_numbers_in_range;

const long MAX_END = 100000L;

fn bool is_kaprekar(long number) {
    if (number == 0L || number == 1L) return true;
    long square = number * number;
    long split = 1L;
    for (long remaining = number; remaining > 0L; remaining /= 10L) split *= 10L;
    long right = square % split;
    return right != 0L && square / split + right == number;
}

fn usz decimal_length(long number) {
    usz length = 1;
    while (number >= 10L) { number /= 10L; length++; }
    return length;
}

fn usz required_length(long start, long end) {
    usz bytes = 0;
    for (long number = start; number <= end; number++)
        if (is_kaprekar(number)) bytes += decimal_length(number) + 1;
    return bytes;
}

fn usz append_decimal(long number, char* output, usz position) {
    char[20] digits;
    usz count = 0;
    do { digits[count++] = (char)('0' + number % 10L); number /= 10L; } while (number > 0L);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

fn long kaprekar_numbers_in_range(long* values, usz length, char* output,
                                  usz output_capacity) @export("kaprekar_numbers_in_range") {
    if (values == null || length != 2) return -1L;
    long start = values[0], end = values[1];
    if (start < 0L || start > end || end > MAX_END) return -1L;
    usz required = required_length(start, end);
    if (output == null || output_capacity < required) return -2L;
    usz position = 0;
    for (long number = start; number <= end; number++) {
        if (!is_kaprekar(number)) continue;
        position = append_decimal(number, output, position);
        output[position++] = '\0';
    }
    return (long)position;
}
