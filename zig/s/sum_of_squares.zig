/// Minimum number of perfect squares summing to value, using Lagrange's theorem.
export fn sum_of_squares(value: i64) i64 {
    if (value < 0 or value > 2_147_483_647) return -1;
    if (value == 0) return 0;

    var low: i64 = 1;
    var high: i64 = value;
    while (high - low > 1) {
        const middle = low + @divTrunc(high - low, 2);
        if (middle <= @divTrunc(value, middle)) low = middle
        else high = middle;
    }
    const root = low;
    if (root * root == value) return 1;

    var second = root;
    var first: i64 = 1;
    while (first <= root) : (first += 1) {
        const remainder = value - first * first;
        while (second * second > remainder) : (second -= 1) {}
        if (second * second == remainder) return 2;
    }

    var reduced = value;
    while (@rem(reduced, 4) == 0) : (reduced = @divTrunc(reduced, 4)) {}
    return if (@rem(reduced, 8) == 7) 4 else 3;
}
