module problem48;

const long MODULUS = 10000000000;

fn long problem48(long ignored) @export("problem48") {
    if (ignored != 0) return -1;
    long total = 0;
    for (long base = 1; base <= 1000; base++) {
        long term = 1;
        for (long exponent = 0; exponent < base; exponent++) {
            term = (term * base) % MODULUS;
        }
        total = (total + term) % MODULUS;
    }
    return total;
}
