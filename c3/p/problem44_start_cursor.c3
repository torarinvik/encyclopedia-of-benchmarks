module problem44_start_cursor;

const long MAX_START = 2166;
const long MAX_HIGH_INDEX = 2167;

fn long pentagonal(long index) {
    return index * (3 * index - 1) / 2;
}

fn long integer_sqrt(long value) {
    long low = 0, high = 20000;
    while (high - low > 1) {
        long middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

fn bool is_pentagonal(long value) {
    long discriminant = 24 * value + 1;
    long root = integer_sqrt(discriminant);
    return root * root == discriminant && (root + 1) % 6 == 0;
}

fn long problem44_start_cursor(long start) @export("problem44_start_cursor") {
    if (start < 1 || start > MAX_START) return -1;
    for (long high = start + 1; high <= MAX_HIGH_INDEX; high++) {
        long high_value = pentagonal(high);
        for (long low = high - 1; low > 0; low--) {
            long low_value = pentagonal(low);
            long difference = high_value - low_value;
            long sum = high_value + low_value;
            if (is_pentagonal(difference) && is_pentagonal(sum)) return difference;
        }
    }
    return -1;
}
