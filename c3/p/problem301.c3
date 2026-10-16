module problem301;

fn long problem301(long exponent) @export("problem301") {
    if (exponent < 0 || exponent > 30) return -1;
    long previous = 0, current = 1;
    for (long index = 0; index < exponent + 2; index++) {
        long next = previous + current;
        previous = current;
        current = next;
    }
    return previous - exponent % 2;
}
