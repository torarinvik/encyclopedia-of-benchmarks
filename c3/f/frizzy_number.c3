module frizzy_number;

fn long frizzy_number(long base, long n) @export("frizzy_number") {
    if (base < 2 || base > 10 || n < 0 || n > 1023) return -1;
    long result = 0;
    long power = 1;
    while (n > 0) {
        if (n % 2 == 1) result += power;
        n /= 2;
        if (n > 0) power *= base;
    }
    return result;
}
