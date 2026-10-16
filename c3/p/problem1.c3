module problem1;

fn long problem1(long limit) @export("problem1") {
    if (limit < 0 || limit > 100000) return -1;
    long sum = 0;
    for (long value = 1; value < limit; value++) {
        if (value % 3 == 0 || value % 5 == 0) sum += value;
    }
    return sum;
}
