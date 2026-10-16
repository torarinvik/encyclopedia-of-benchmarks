module problem164;

fn long problem164(long n_digits) @export("problem164") {
    if (n_digits < 0 || n_digits > 26) return -1;
    if (n_digits == 0) return 1;

    long[100] current = {0};
    long[100] next = {0};
    for (long first = 1; first <= 9; first++) current[first * 10] = 1;

    for (long used = 1; used < n_digits; used++) {
        for (long index = 0; index < 100; index++) next[index] = 0;
        for (long previous = 0; previous <= 9; previous++) {
            for (long before_previous = 0; before_previous <= 9; before_previous++) {
                long ways = current[previous * 10 + before_previous];
                long maximum_digit = 9 - previous - before_previous;
                for (long digit = 0; digit <= maximum_digit; digit++)
                    next[digit * 10 + previous] += ways;
            }
        }
        for (long index = 0; index < 100; index++) current[index] = next[index];
    }

    long total = 0;
    for (long index = 0; index < 100; index++) total += current[index];
    return total;
}
