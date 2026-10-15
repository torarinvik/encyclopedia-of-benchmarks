module count_numbers_divisible;

// Count multiples of divisor in the inclusive positive integer interval [first, last].
fn double count_numbers_divisible(double first, double last, double divisor) @export("count_numbers_divisible") {
    long a = (long)first;
    long b = (long)last;
    long m = (long)divisor;
    return (double)(b / m - (a - 1) / m);
}
