module problem44;

extern fn double sqrt(double value);

fn bool is_pentagonal(long value) {
    if (value < 1) return false;
    long discriminant = 24 * value + 1;
    long root = (long)sqrt((double)discriminant);
    return root * root == discriminant && (root + 1) % 6 == 0;
}

fn long problem44(long limit) @export("problem44") {
    if (limit < 1 || limit > 5000) return -1;
    for (long i = 1; i < limit; i++) {
        long first = i * (3 * i - 1) / 2;
        for (long j = i; j < limit; j++) {
            long second = j * (3 * j - 1) / 2;
            long difference = second - first;
            if (is_pentagonal(first + second) && is_pentagonal(difference)) return difference;
        }
    }
    return -1;
}
