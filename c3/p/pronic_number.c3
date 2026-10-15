module pronic_number;

extern fn double sqrt(double value);

fn long pronic_number(long n) @export("pronic_number") {
    if (n < 0 || n > 2147483647) return -1;
    long root = (long)sqrt((double)n);
    return root * (root + 1) == n ? 1 : 0;
}
