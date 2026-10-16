module problem2;

fn long problem2(long limit) @export("problem2") {
    if (limit < 0 || limit > 4000000) return -1;
    long previous = 1;
    long current = 2;
    long sum = 0;
    while (current < limit) {
        if (current % 2 == 0) sum += current;
        long next = previous + current;
        previous = current;
        current = next;
    }
    return sum;
}
