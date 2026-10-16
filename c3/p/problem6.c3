module problem6;

fn long problem6(long limit) @export("problem6") {
    if (limit < 0 || limit > 100) return -1;
    long sum = 0;
    long sum_of_squares = 0;
    for (long value = 1; value <= limit; value++) {
        sum += value;
        sum_of_squares += value * value;
    }
    return sum * sum - sum_of_squares;
}
