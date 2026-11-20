const long MAX_LIMIT = 100000;
const usz MAX_PARSEABLE_LENGTH = 2;
const usz WORD_COUNT = 1563;

fn long digit_sum10(long value) {
    long sum = 0;
    while (value > 0) {
        sum += value % 10;
        value /= 10;
    }
    return sum;
}

fn long self_number_count_sieve(long* input, usz length) @export("self_number_count_sieve") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long limit = input[0];
    if (length != 1 || limit < 1 || limit > MAX_LIMIT) return -1;

    ulong[WORD_COUNT] generated = {};
    for (long source = 1; source <= limit; source += 1) {
        long target = source + digit_sum10(source);
        if (target <= limit) generated[(usz)(target / 64)] |= 1ul << (usz)(target % 64);
    }
    long count = 0;
    for (long value = 1; value <= limit; value += 1) {
        if ((generated[(usz)(value / 64)] & (1ul << (usz)(value % 64))) == 0) count += 1;
    }
    return count;
}
