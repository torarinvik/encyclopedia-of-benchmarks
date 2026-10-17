module so1;

fn long so1(long threshold) @export("so1") {
    if (threshold < -2147483648L || threshold > 1000000000L) return -1;

    long first = 1;
    long second = 2;
    long sum = 0;
    while (second <= threshold) {
        if (second % 2 == 0) sum += second;
        long temporary = first;
        first = second;
        second = temporary + first;
    }
    return sum;
}
