module keith_number;

fn long keith_number(long number) @export("keith_number")
{
    if (number < 10 || number > 999999) return -1;

    long[6] reversed;
    long[6] digits;
    long value = number;
    long digit_count = 0;
    while (value > 0) {
        reversed[digit_count] = value % 10;
        digit_count += 1;
        value /= 10;
    }
    for (long i = 0; i < digit_count; i += 1) {
        digits[i] = reversed[digit_count - 1 - i];
    }

    long oldest = 0;
    while (true) {
        long next = 0;
        for (long i = 0; i < digit_count; i += 1) {
            next += digits[(oldest + i) % digit_count];
        }
        if (next >= number) return next == number ? 1 : 0;
        digits[oldest] = next;
        oldest = (oldest + 1) % digit_count;
    }
}
