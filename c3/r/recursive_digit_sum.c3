module recursive_digit_sum;

fn long recursive_digit_sum(long number, long repetitions) @export("recursive_digit_sum") {
    if (number < 0 || repetitions < 0 || repetitions > 1000000) return -1;
    long digit_sum = 0;
    do {
        digit_sum += number % 10;
        number /= 10;
    } while (number != 0);
    long total = digit_sum * repetitions;
    while (total >= 10) {
        long next = 0;
        do {
            next += total % 10;
            total /= 10;
        } while (total != 0);
        total = next;
    }
    return total;
}
