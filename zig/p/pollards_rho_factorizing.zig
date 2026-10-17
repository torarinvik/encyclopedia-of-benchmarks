const MIN_N: i64 = 2;
const MAX_N: i64 = 46_340;

fn nextValue(n: i64, x: i64) i64 {
    return @rem(x * x + 1, n);
}

fn gcdNonnegative(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

export fn pollards_rho_factorizing(n: i64) i64 {
    if (n < MIN_N or n > MAX_N) return -1;
    var x: i64 = 2;
    var y: i64 = 2;
    var divisor: i64 = 1;
    while (divisor == 1) {
        x = nextValue(n, x);
        y = nextValue(n, nextValue(n, y));
        const difference = if (x >= y) x - y else y - x;
        divisor = gcdNonnegative(difference, n);
    }
    return divisor;
}
