module problem100;

const long MAX_MIN_TOTAL = 1000000000000;

fn long problem100(long min_total) @export("problem100") {
    if (min_total < 0 || min_total > MAX_MIN_TOTAL) return -1;
    long previous_numerator = 1, previous_denominator = 0;
    long numerator = 1, denominator = 1;
    while (numerator <= 2 * min_total - 1) {
        previous_numerator += 2 * numerator;
        numerator += 2 * previous_numerator;
        previous_denominator += 2 * denominator;
        denominator += 2 * previous_denominator;
    }
    return (denominator + 1) / 2;
}
