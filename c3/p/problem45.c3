module problem45;

const long MAX_ROOT = 200000;
const long MAX_INDEX = 27693;

fn long integer_sqrt(long value) {
    long low = 0, high = MAX_ROOT;
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

fn long problem45(long start) @export("problem45") {
    if (start < 0 || start > MAX_INDEX) return -1;
    for (long index = start; index <= MAX_INDEX; index++) {
        long value = index * (2 * index - 1);
        if (is_pentagonal(value)) return value;
    }
    return -1;
}
