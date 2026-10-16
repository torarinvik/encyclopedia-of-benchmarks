module problem7;

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long factor = 2; factor <= value / factor; factor++) {
        if (value % factor == 0) return false;
    }
    return true;
}

fn long problem7(long index) @export("problem7") {
    if (index < 1 || index > 10001) return -1;
    long count = 0;
    long candidate = 1;
    while (count < index) {
        candidate++;
        if (is_prime(candidate)) count++;
    }
    return candidate;
}
