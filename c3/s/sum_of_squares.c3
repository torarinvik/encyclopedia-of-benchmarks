module sum_of_squares;

// Minimum number of perfect squares summing to value, using Lagrange's theorem.
fn long sum_of_squares(long value) @export("sum_of_squares")
{
    if (value < 0 || value > 2147483647) return -1;
    if (value == 0) return 0;

    long low = 1;
    long high = value;
    while (high - low > 1) {
        long middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            low = middle;
        } else {
            high = middle;
        }
    }
    long root = low;
    if (root * root == value) return 1;

    long second = root;
    for (long first = 1; first <= root; first++) {
        long remainder = value - first * first;
        while (second * second > remainder) second--;
        if (second * second == remainder) return 2;
    }

    long reduced = value;
    while (reduced % 4 == 0) reduced /= 4;
    return reduced % 8 == 7 ? 4 : 3;
}
