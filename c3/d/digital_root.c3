module digital_root;

fn long digital_root(long n) @export("digital_root")
{
    if (n < 0) return -1;
    while (n >= 10) {
        long total = 0;
        while (n > 0) {
            total += n % 10;
            n /= 10;
        }
        n = total;
    }
    return n;
}
