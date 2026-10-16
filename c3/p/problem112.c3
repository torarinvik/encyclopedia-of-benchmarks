module problem112;

fn bool is_bouncy(long value) {
    bool increasing = false;
    bool decreasing = false;
    long previous = value % 10;
    value /= 10;
    while (value > 0) {
        long digit = value % 10;
        if (digit < previous) increasing = true;
        if (digit > previous) decreasing = true;
        previous = digit;
        value /= 10;
    }
    return increasing && decreasing;
}

fn long problem112(long percent) @export("problem112") {
    if (percent < 1 || percent > 99) return -1;
    long bouncy = 0;
    for (long n = 1; ; n++) {
        if (is_bouncy(n)) bouncy++;
        if (bouncy * 100 >= percent * n) return n;
    }
}
