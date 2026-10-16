module problem64;

const long MAX_LIMIT = 10000;

fn long integer_sqrt(long value) {
    long low = 0;
    long high = value + 1;
    while (high - low > 1) {
        long middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

fn long period_length(long value, long root) {
    long numerator = 0;
    long denominator = 1;
    long coefficient = root;
    long period = 0;
    do {
        numerator = denominator * coefficient - numerator;
        denominator = (value - numerator * numerator) / denominator;
        coefficient = (root + numerator) / denominator;
        ++period;
    } while (coefficient != 2 * root);
    return period;
}

fn long problem64(long inclusive_limit) @export("problem64") {
    if (inclusive_limit < 0 || inclusive_limit > MAX_LIMIT) return -1;
    long count = 0;
    for (long value = 2; value <= inclusive_limit; ++value) {
        long root = integer_sqrt(value);
        if (root * root == value) continue;
        if (period_length(value, root) % 2 == 1) ++count;
    }
    return count;
}
