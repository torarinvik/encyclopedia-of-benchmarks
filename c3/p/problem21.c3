module problem21;

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

fn long problem21(long limit) @export("problem21") {
    if (limit < 1 || limit > 10000) return -1;
    long total = 0;
    for (long value = 1; value < limit; value++) {
        long partner = proper_divisor_sum(value);
        if (partner != value && proper_divisor_sum(partner) == value) total += value;
    }
    return total;
}
