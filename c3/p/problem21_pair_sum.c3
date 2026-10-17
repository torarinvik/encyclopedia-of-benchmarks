module problem21_pair_sum;

fn long proper_divisor_sum(long value) {
    if (value <= 1) return 0;
    long sum = 1;
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor != 0) continue;
        long partner = value / divisor;
        sum += divisor;
        if (partner != divisor) sum += partner;
    }
    return sum;
}

fn long problem21_pair_sum(long limit) @export("problem21_pair_sum") {
    if (limit < 2 || limit > 10000) return -1;
    long total = 0;
    for (long smaller = 2; smaller < limit; smaller++) {
        long larger = proper_divisor_sum(smaller);
        if (larger > smaller && proper_divisor_sum(larger) == smaller) {
            total += smaller + larger;
        }
    }
    return total;
}
