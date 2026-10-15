module hardy_ramanujanalgo;

fn long hardy_ramanujanalgo(long n) @export("hardy_ramanujanalgo") {
    if (n < 1 || n > 2147483647) return -1;

    long count = 0;
    if (n % 2 == 0) count += 1;
    while (n % 2 == 0) n /= 2;

    long factor = 3;
    while (factor <= n / factor) {
        if (n % factor == 0) {
            count += 1;
            while (n % factor == 0) n /= factor;
        }
        factor += 2;
    }
    if (n > 2) count += 1;
    return count;
}
