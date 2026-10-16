module problem12_sol1;

fn long divisor_count(long value) {
    long count = 1;
    for (long factor = 2; factor <= value / factor; factor++) {
        long multiplicity = 0;
        while (value % factor == 0) {
            value /= factor;
            multiplicity++;
        }
        if (multiplicity != 0) count *= multiplicity + 1;
    }
    if (value > 1) count *= 2;
    return count;
}

fn long problem12_sol1(long threshold) @export("problem12_sol1") {
    if (threshold != 500) return -1;
    long index = 1;
    long triangular = 1;
    while (true) {
        index++;
        triangular += index;
        if (divisor_count(triangular) > 500) return triangular;
    }
}
