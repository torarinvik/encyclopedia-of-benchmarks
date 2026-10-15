module dudeney_number;

fn long dudeney_number(long number) @export("dudeney_number") {
    if (number <= 0 || number > 2147483647) return -1;
    long low = 1;
    long high = 1290;
    long root = 0;
    while (low <= high) {
        long middle = low + (high - low) / 2;
        long cube = middle * middle * middle;
        if (cube == number) { root = middle; break; }
        if (cube < number) low = middle + 1;
        else high = middle - 1;
    }
    if (root == 0) return 0;
    long remaining = number;
    long sum = 0;
    while (remaining > 0) { sum += remaining % 10; remaining /= 10; }
    return sum == root ? 1 : 0;
}
