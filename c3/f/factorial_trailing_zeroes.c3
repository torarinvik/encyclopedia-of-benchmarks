module factorial_trailing_zeroes;

const long MAX_N = 1000000000;

// Count factors of five in n!, which determine its trailing decimal zeros.
fn long factorial_trailing_zeroes(long n) @export("factorial_trailing_zeroes") {
    if (n < 0 || n > MAX_N) return -1;
    long count = 0;
    while (n > 0) {
        n /= 5;
        count += n;
    }
    return count;
}
