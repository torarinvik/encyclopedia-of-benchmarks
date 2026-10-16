module problem17;

fn long problem17(long limit) @export("problem17") {
    if (limit < 0 || limit > 1000) return -1;
    long[20] ones = {0, 3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8};
    long[10] tens = {0, 0, 6, 6, 5, 5, 5, 7, 6, 6};
    long total = 0;
    for (long value = 1; value <= limit; value++) {
        if (value == 1000) {
            total += ones[1] + 8;
            continue;
        }
        long remainder = value;
        if (value >= 100) {
            total += ones[value / 100] + 7;
            remainder = value % 100;
            if (remainder != 0) total += 3;
        }
        if (remainder < 20) total += ones[remainder];
        else total += tens[remainder / 10] + ones[remainder % 10];
    }
    return total;
}
